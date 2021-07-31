defmodule Playwright.Runner.Connection do
  @moduledoc false

  use GenServer
  require Logger

  alias Playwright.Extra
  alias Playwright.Runner.Callback
  alias Playwright.Runner.Catalog
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Root
  alias Playwright.Runner.Transport

  # API
  # ----------------------------------------------------------------------------

  @type transport_module :: module()
  @type transport_config :: {transport_module, [term()]}

  defstruct(
    callbacks: %{},
    catalog: nil,
    transport: nil
  )

  @spec start_link(transport_config) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  # Catalog or callback(`GenServer.reply`).
  # - Like `find` (now another `get`, below), does not send/post.
  # - Unlike `find` (`get`, below), will register a "from" to receive a reply, if not already in the catalog.
  def get(connection, {:guid, _guid} = item) do
    GenServer.call(connection, {:get, item})
  end

  # Catalog-only.
  # - Attempts to retrieve an existing entry, and returns that or "default".
  # - Could probably be collapsed with `get` (above), with some options or similar.
  def get(connection, attributes, default \\ []) do
    GenServer.call(connection, {:get, attributes, default})
  end

  # Callback-only (remote event).
  # - Registers a handler (can have multiple... consider MultiDict from "Elixir in Action").
  # - No Catalog interaction. !!! This is likely to change, as the listeners/handlers
  #   should be closely related to a specific and particular resource.
  # - Does not yet have any handling of `once`, `off`, etc.
  # - Could perhaps move to Channel. That would more closely match other implementations
  #   and is feasible given that ChannelOwner/subject structs have `connection`.
  def on(connection, {event, subject}, handler) do
    GenServer.cast(connection, {:on, {event, subject}, handler})
  end

  # Catalog-only.
  # - Updates the state of a resource and returns the updated resource.
  # - Assumes existence.
  def patch(connection, {:guid, _guid} = subject, data) do
    GenServer.call(connection, {:patch, subject, data})
  end

  # Transport-bound + callback(`GenServer.reply`)
  # - Is the one "API function" that sends to/over the Transport.
  # - Registers a "from" to receive the reply (knowing it will NOT be in the Catalog).
  # - ...in fact, any related Catalog changes are side-effects, likely delivered via an Event.
  @spec post(pid(), Channel.Command.t()) :: term()
  def post(connection, command) do
    GenServer.call(connection, {:post, {:cmd, command}})
  end

  # Transport-bound.
  # - Is the one "API function" that receives from the Transport.
  # - ...therefore, all `reply`, `handler`, etc. "clearing" MUST originate here.
  def recv(connection, {:text, _json} = message) do
    GenServer.cast(connection, {:recv, message})
  end

  # @impl
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init({transport_module, config}) do
    Logger.debug("Starting up Playwright with config: #{inspect(config)}")

    {:ok, catalog} = Catalog.Server.start_link(Root.new(self()))

    {:ok,
     %__MODULE__{
      #  catalog: Catalog.new(Root.new(self())),
       catalog: catalog,
       transport: Transport.connect(transport_module, [self()] ++ config)
     }}
  end

  @impl GenServer
  def handle_call({:get, {:guid, guid}}, subscriber, %{catalog: catalog} = state) do
    # {:noreply, %{state | catalog: Catalog.get(catalog, guid, subscriber)}}
    Catalog.Server.get(catalog, guid, subscriber)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, filter, default}, _from, %{catalog: catalog} = state) do
    {:reply, Catalog.Server.find(catalog, filter, default), state}
  end

  # NOTE: this should move to be part of `Catalog.put`
  @impl GenServer
  def handle_call({:patch, {:guid, guid}, data}, _from, %{catalog: catalog} = state) do
    subject = Map.merge(Catalog.Server.get(catalog, guid), data)
    Catalog.Server.put(catalog, subject)
    {:reply, subject, state}
  end

  @impl GenServer
  def handle_call({:post, {:cmd, message}}, from, %{callbacks: callbacks, transport: transport} = state) do
    # Logger.warn("POST: #{inspect(message.id)}: #{inspect(message)}")
    Transport.post(transport, Jason.encode!(message))

    {
      :noreply,
      %{state | callbacks: Map.put(callbacks, message.id, Callback.new(from, message))}
    }
  end

  @impl GenServer
  def handle_cast({:on, {event, subject}, handler}, %{catalog: catalog} = state) do
    listeners = [handler | subject.listeners[event] || []]
    subject = %{subject | listeners: %{event => listeners}}

    Catalog.Server.put(catalog, subject)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:recv, {:text, json}}, state) do
    recv_payload(json, state)
  end

  # private
  # ----------------------------------------------------------------------------

  defp recv_payload(<<json::binary>>, state) do
    case Jason.decode(json) do
      {:ok, data} ->
        state = recv_payload(data |> Extra.Map.deep_atomize_keys(), state)
        {:noreply, state}

      _error ->
        raise ArgumentError, message: inspect(json: Enum.join(for <<c::utf8 <- json>>, do: <<c::utf8>>))
    end
  end

  defp recv_payload(%{id: message_id} = message, %{callbacks: callbacks, catalog: catalog} = state) do
    {callback, updated} = Map.pop!(callbacks, message_id)
    Callback.resolve(callback, Channel.Response.new(message, catalog))

    %{state | callbacks: updated}
  end

  defp recv_payload(%{method: _method} = event, %{catalog: catalog} = state) do
    Channel.Event.handle(event, catalog)
    state
  end
end
