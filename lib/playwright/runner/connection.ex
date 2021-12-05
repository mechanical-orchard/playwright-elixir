defmodule Playwright.Runner.Connection do
  @moduledoc false
  use GenServer
  alias Playwright.Extra
  alias Playwright.Runner.{Catalog, Channel, ConnectionID, EventInfo, Transport}

  require Logger

  @type transport_module :: module()
  @type transport_config :: {transport_module, [term()]}

  defstruct(
    awaiting: %{},
    callbacks: %{},
    catalog: nil,
    transport: nil
  )

  def child_spec(transport_config) do
    %{
      id: {__MODULE__, ConnectionID.next()},
      start: {
        __MODULE__,
        :start_link,
        [transport_config]
      },
      restart: :transient
    }
  end

  @spec start_link(transport_config) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  @spec bind(pid(), {atom(), struct()}, function()) :: term()
  def bind(connection, {event, subject}, callback) do
    # event = Atom.to_string(event)
    GenServer.cast(connection, {:bind, {event, subject}, callback})
  end

  # ---

  def all(connection, filter) do
    GenServer.call(connection, {:all, filter})
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
  def get(connection, attributes) do
    GenServer.call(connection, {:get, attributes})
  end

  # Callback-only (remote event).
  # - Registers a handler (can have multiple... consider MultiDict from "Elixir in Action").
  # - No Catalog interaction. !!! This is likely to change, as the listeners/handlers
  #   should be closely related to a specific and particular resource.
  # - Does not yet have any handling of `once`, `off`, etc.
  # - Could perhaps move to Channel. That would more closely match other implementations
  #   and is feasible given that ChannelOwner/subject structs have `connection`.
  @spec on(pid(), {binary(), struct()}, function()) :: term()
  def on(connection, {event, owner}, callback) do
    GenServer.cast(connection, {:on, {event, owner}, callback})
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
  @spec post(pid(), Channel.Command.t()) :: {:ok, term()} | {:error, term()}
  def post(connection, command) do
    timeout = command.params |> Map.get(:timeout, 30_000)
    GenServer.call(connection, {:post, {:cmd, command}}, timeout + 5_000)
  end

  # Transport-bound.
  # - Is the one "API function" that receives from the Transport.
  # - ...therefore, all `reply`, `handler`, etc. "clearing" MUST originate here.
  def recv(connection, {:text, _json} = message) do
    GenServer.cast(connection, {:recv, message})
  end

  @spec wait_for(pid(), {atom(), struct()}, (() -> any())) :: {:ok, EventInfo.t()}
  def wait_for(connection, {event, owner}, action) do
    GenServer.call(connection, {:wait_for, {event, owner}, action})
  end

  # @impl
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init({transport_module, config}) do
    # Logger.warn("Starting up Playwright with config: #{inspect(config)}")
    # Logger.warn("  --> will connect w/ #{inspect([self()] ++ config)}")

    {:ok, catalog} = Catalog.start_link(Channel.Root.new(self()))

    state = %__MODULE__{
      catalog: catalog,
      transport: Transport.connect(transport_module, {self(), config})
    }

    {:ok, state, {:continue, :initialize}}
  end

  @impl GenServer
  def handle_continue(:initialize, %{transport: transport} = state) do
    message = %{
      guid: "",
      method: "initialize",
      params: %{sdkLanguage: "elixir"},
      # NOTE: things blow up without the presence of this `metadata`.
      metadata: %{}
    }

    Transport.post(transport, Jason.encode!(message))

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:all, filter}, _from, %{catalog: catalog} = state) do
    {:reply, Catalog.filter(catalog, filter), state}
  end

  @impl GenServer
  def handle_call({:get, {:guid, guid}}, from, %{catalog: catalog} = state) do
    Catalog.get(catalog, guid, from)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, filter}, _from, %{catalog: catalog} = state) do
    {:reply, Catalog.filter(catalog, filter, nil), state}
  end

  # these 2 ^v :get handlers are not really alike... redefine them, please :)

  # NOTE: this should move to be part of `Catalog.put`
  @impl GenServer
  def handle_call({:patch, {:guid, guid}, data}, _from, %{catalog: catalog} = state) do
    # NOTE: It's possible that the resource has been removed from the Catalog
    # (e.g., on `Page.close`). It may be that there's a more sensible way to
    # handle such scenarios, but this will do for now.
    subject =
      case Catalog.get(catalog, guid) do
        nil ->
          nil

        subject ->
          Map.merge(subject, data)
      end

    if subject do
      Catalog.put(catalog, subject)
    end

    {:reply, subject, state}
  end

  @impl GenServer
  def handle_call({:post, {:cmd, message}}, from, %{callbacks: callbacks, transport: transport} = state) do
    Transport.post(transport, Jason.encode!(message))

    {
      :noreply,
      %{state | callbacks: Map.put(callbacks, message.id, Channel.Callback.new(from, message))}
    }
  end

  # GenServer.call(connection, {:add_wait, {event, owner}})
  # GenServer.call(connection, {:wait_for, {event, owner}, action})

  @impl GenServer
  def handle_call({:wait_for, {event, owner}, trigger}, from, %{awaiting: awaiting} = state) do
    callback = fn event_info ->
      GenServer.reply(from, event_info)
    end

    key = {event, owner.guid}
    updated = Map.get(awaiting, key, []) ++ [callback]

    # race?
    Task.start_link(trigger)
    {:noreply, %{state | awaiting: Map.put(awaiting, key, updated)}}
  end

  @impl GenServer
  def handle_cast({:bind, {event, owner}, callback}, %{catalog: catalog} = state) do
    # NOTE: need to be sure we're using the latest, in case of multiple calls
    # to `Channel.bind` within a given `ChannelOwner.init`, for example.
    owner = Catalog.get(catalog, owner.guid)

    # NOTE: order is important (must append) because we need the
    # `ChannelOwner.init` bindings to execute before any others
    # (e.g., for state changes).
    listeners = (owner.listeners[event] || []) ++ [callback]
    listeners = Map.put(owner.listeners, event, listeners)

    Catalog.put(catalog, %{owner | listeners: listeners})
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:on, {event, owner}, callback}, %{catalog: catalog} = state) do
    listeners = [callback | owner.listeners[event] || []]
    listeners = Map.put(owner.listeners, event, listeners)

    owner = %{owner | listeners: listeners}

    Catalog.put(catalog, owner)
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

  defp recv_payload(%{error: error, id: message_id}, %{callbacks: callbacks, catalog: catalog} = state) do
    Logger.debug("recv_payload E: #{inspect(error)}")

    {callback, updated} = Map.pop!(callbacks, message_id)
    Channel.Callback.resolve(callback, Channel.Error.new(error, catalog))
    %{state | callbacks: updated}
  end

  defp recv_payload(%{id: message_id} = message, %{callbacks: callbacks, catalog: catalog} = state) do
    Logger.debug("recv_payload A: #{inspect(message)}")

    {callback, updated} = Map.pop!(callbacks, message_id)
    Channel.Callback.resolve(callback, Channel.Response.new(message, catalog))
    %{state | callbacks: updated}
  end

  defp recv_payload(%{guid: guid, method: method} = message, %{awaiting: awaiting, catalog: catalog} = state) do
    Logger.debug("recv_payload B: #{inspect(message)}")

    awaiting_key = {Extra.Atom.snakecased(method), guid}
    callbacks = Map.get(awaiting, awaiting_key, [])

    :ok = Channel.Event.handle(message, catalog, callbacks)
    state
  end

  # - %{playwright: %{guid: "Playwright"}}
  defp recv_payload(%{result: _result} = _message, %{catalog: _catalog} = state) do
    # Logger.debug("recv_payload C: #{inspect(message)}")
    state
  end
end
