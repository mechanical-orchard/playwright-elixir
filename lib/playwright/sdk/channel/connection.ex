defmodule Playwright.SDK.Channel.Connection do
  @moduledoc false
  use GenServer
  require Logger
  alias Playwright.SDK.{Channel, Extra, Transport}

  defstruct(
    callbacks: %{},
    session: nil,
    transport: nil
  )

  # module init
  # ---------------------------------------------------------------------------

  def start_link({session, transport}) do
    GenServer.start_link(__MODULE__, {session, transport})
  end

  # @impl init
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init({session, transport}) do
    state = %__MODULE__{
      session: session,
      transport: Transport.start_link!({self(), transport})
    }

    {:ok, state, {:continue, :initialize}}
  end

  @impl GenServer
  def handle_continue(:initialize, %{transport: transport} = state) do
    message = %{
      guid: "",
      method: "initialize",
      # playwright v1.38.0 introduced an assertion on `sdkLanguage`.
      # for now, we fake it.
      # params: %{sdkLanguage: "elixir"},
      params: %{sdkLanguage: "javascript"},
      metadata: %{}
    }

    # message = Channel.Message.new("", :initialize, %{sdkLanguage: "elixir"})
    Transport.post(transport, message)
    {:noreply, state}
  end

  # module API
  # ---------------------------------------------------------------------------

  # Transport-bound + callback(`GenServer.reply`)
  # - Is the one "API function" that sends to/over the Transport.
  # - Registers a "from" to receive the reply (knowing it will NOT be in the Catalog).
  # - ...in fact, any related Catalog changes are side-effects, likely delivered via an Event.
  # @spec post(pid(), Channel.Message.t()) :: {:ok, term()} | {:error, term()}
  def post(connection, message, timeout) do
    GenServer.call(connection, {:post, message}, timeout)
  end

  # Transport-bound.
  # - Is the one "API function" that receives from the Transport.
  # - ...therefore, all `reply`, `handler`, etc. "clearing" MUST originate here.
  def recv(connection, message) do
    GenServer.cast(connection, {:recv, message})
  end

  # @spec wait_for(pid(), {atom(), struct()}, (() -> any())) :: {:ok, Event.t()}
  def wait(connection, owner, event, timeout, trigger \\ nil) do
    GenServer.call(connection, {:wait, {owner, event}, trigger}, timeout)
  end

  # @impl callbacks
  # ----------------------------------------------------------------------------

  @impl GenServer
  def handle_call({:post, message}, from, %{callbacks: callbacks, transport: transport} = state) do
    Transport.post(transport, message)
    key = {:message, message.id}
    {:noreply, %{state | callbacks: Map.put(callbacks, key, from)}}
  end

  @impl GenServer
  def handle_call({:wait, {{:guid, guid}, event}, trigger}, from, %{callbacks: callbacks} = state) do
    # Would `:continue` (which is allowed) be better here?
    if trigger do
      Task.start_link(trigger)
    end

    key = {as_atom(event), guid}
    {:noreply, %{state | callbacks: Map.put(callbacks, key, from)}}
  end

  @impl GenServer
  def handle_cast({:recv, response}, %{callbacks: callbacks, session: session} = state) do
    update =
      case response do
        %{id: message_id} ->
          key = {:message, message_id}
          {from, callbacks} = Map.pop!(callbacks, key)
          Channel.recv(session, {from, response})
          %{state | callbacks: callbacks}

        %{guid: guid, method: method} ->
          key = {as_atom(method), guid}
          {from, callbacks} = Map.pop(callbacks, key)
          Channel.recv(session, {from, response})
          %{state | callbacks: callbacks}

        %{result: _result} ->
          Channel.recv(session, {nil, response})
          state
      end

    {:noreply, update}
  end

  # private
  # ----------------------------------------------------------------------------

  defp as_atom(value) when is_atom(value) do
    value
  end

  defp as_atom(value) when is_binary(value) do
    Extra.Atom.snakecased(value)
  end
end
