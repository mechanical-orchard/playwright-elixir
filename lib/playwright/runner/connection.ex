defmodule Playwright.Runner.Connection do
  @moduledoc false
  require Logger

  use GenServer

  alias Playwright.Extra
  alias Playwright.Runner.Callback
  alias Playwright.Runner.Catalog
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Transport

  # API
  # ----------------------------------------------------------------------------

  @type transport_module :: module()
  @type transport_config :: {transport_module, [term()]}

  defstruct(
    callbacks: %{},
    catalog: nil,
    handlers: %{}, # !!!
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
  # - No Catalog interaction.
  # - Does not yet have any handling of `once`, `off`, etc.
  def on(connection, event, handler) do
    GenServer.call(connection, {:on, event, handler})
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

    {:ok,
     %__MODULE__{
       catalog: Catalog.new(self()),
       transport: Transport.connect(transport_module, [self()] ++ config)
     }}
  end

  @impl GenServer
  def handle_call({:get, {:guid, guid}}, subscriber, %{catalog: catalog} = state) do
    {:noreply, %{state | catalog: Catalog.await(catalog, guid, subscriber)}}
  end

  @impl GenServer
  def handle_call({:get, filter, default}, _from, %{catalog: catalog} = state) do
    {:reply, Catalog.find(catalog, filter, default), state}
  end

  @impl GenServer
  def handle_call({:on, event, handler}, _from, %{handlers: handlers} = state) do
    updated = Map.update(handlers, event, [handler], fn existing -> [handler | existing] end)
    {:reply, :ok, %{state | handlers: updated}}
  end

  @impl GenServer
  def handle_call({:patch, {:guid, guid}, data}, _from, %{catalog: catalog} = state) do
    subject = Map.merge(catalog[guid], data)
    catalog = Catalog.put(catalog, guid, subject)
    {:reply, subject, %{state | catalog: catalog}}
  end

  @impl GenServer
  def handle_call({:post, {:cmd, message}}, from, %{callbacks: callbacks, transport: transport} = state) do
    Logger.warn("POST: #{inspect(message.id)}: #{inspect(message)}")
    Transport.post(transport, Jason.encode!(message))

    {
      :noreply,
      %{state | callbacks: Map.put(callbacks, message.id, Callback.new(from, message))}
    }
  end

  @impl GenServer
  def handle_cast({:recv, {:text, json}}, state) do
    {:noreply, _recv_(json, state)}
  end

  # private
  # ----------------------------------------------------------------------------

  defp _del_(guid, catalog) do
    children = Catalog.find(catalog, %{parent: Catalog.get(catalog, guid)}, [])

    catalog =
      children
      |> Enum.reduce(catalog, fn item, acc ->
        _del_(item.guid, acc)
      end)

    Catalog.delete(catalog, guid)
  end

  defp _recv_(json, state) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, data} ->
        _recv_(data |> Extra.Map.deep_atomize_keys(), state)

      _error ->
        raise ArgumentError, message: inspect(json: Enum.join(for <<c::utf8 <- json>>, do: <<c::utf8>>))
    end
  end

  # receiving with an ID (channel:response... exec callback)
  defp _recv_(%{id: message_id, result: result} = data, state) do
    Logger.warn("RECa: #{inspect(message_id)}: #{inspect(data)}")

    case Map.to_list(result) do
      [{_key, %{guid: guid}}] ->
        reply_from_catalog({message_id, guid}, state)

      [{:binary, value}] ->
        reply_with_binary({message_id, value}, state)

      [{:elements, list}] ->
        reply_with_list({message_id, list}, state)

      [{:value, value}] ->
        reply_with_value({message_id, value}, state)

      [] ->
        reply_with_value({message_id, nil}, state)
    end
  end

  # receiving with an ID (channel:response... exec callback)
  defp _recv_(%{id: message_id} = data, state) do
    Logger.warn("RECb: #{inspect(message_id)}: #{inspect(data)}")
    reply_from_messages({message_id, data}, state)
  end

  # Workaround: Playwright sends back empty string: "" for top-level objects,
  # to be attached to the "Root". So, let's at least rename the parent as
  # "Root", instead of "", respectively.
  defp _recv_(%{guid: ""} = data, state) do
    _recv_(Map.put(data, :guid, "Root"), state)
  end

  # channel:event (special)
  defp _recv_(
         %{guid: parent_guid, method: "__create__", params: params},
         %{catalog: catalog} = state
       ) do
    item = apply(resource(params), :new, [Catalog.get(catalog, parent_guid), params])
    %{state | catalog: Catalog.put(catalog, item.guid, item)}
  end

  # channel:event (special)
  defp _recv_(%{guid: guid, method: "__dispose__"}, %{catalog: catalog} = state) do
    Logger.debug("__dispose__ #{inspect(guid)}")
    %{state | catalog: _del_(guid, catalog)}
  end

  # channel:event (emit(method, channels))
  defp _recv_(%{guid: guid, method: method}, %{catalog: catalog, handlers: handlers} = state)
       when method in ["close"] do
    entry = Catalog.get(catalog, guid)
    entry = Map.put(entry, :initializer, Map.put(entry.initializer, :isClosed, true))
    event = {:on, Extra.Atom.from_string(method), entry}
    handlers = Map.get(handlers, method, [])

    Enum.each(handlers, fn handler ->
      handler.(event)
    end)

    %{state | catalog: Catalog.put(catalog, guid, entry)}
  end

  # channel:event (emit(method, channels))
  defp _recv_(%{guid: guid, method: method, params: params}, %{catalog: catalog} = state)
       when method in ["previewUpdated"] do
    Logger.debug("preview updated for #{inspect(guid)}")
    updated = %Playwright.ElementHandle{Catalog.get(catalog, guid) | preview: params.preview}
    %{state | catalog: Catalog.put(catalog, guid, updated)}
  end

  # channel:event (emit(method, channels))
  defp _recv_(%{method: method, params: %{message: %{guid: guid}}}, %{catalog: catalog, handlers: handlers} = state)
       when method in ["console"] do
    entry = Catalog.get(catalog, guid)
    event = {:on, Extra.Atom.from_string(method), entry}
    handlers = Map.get(handlers, method, [])

    Enum.each(handlers, fn handler ->
      handler.(event)
    end)

    state
  end

  defp _recv_(data, state) do
    Logger.debug("_recv_ UNKNOWN :: method: #{inspect(data.method)}; data: #{inspect(data)}")
    state
  end

  defp resource(%{type: type}) do
    String.to_existing_atom("Elixir.Playwright.#{type}")
  rescue
    ArgumentError ->
      message = "ChannelOwner of type #{inspect(type)} is not yet defined"
      Logger.debug(message)
      exit(message)
  end

  # channel:response
  defp reply_from_catalog({message_id, guid}, %{callbacks: callbacks, catalog: catalog} = state) do
    resource = Catalog.get(catalog, guid)

    {callback, updated} = Map.pop!(callbacks, message_id)
    Callback.resolve(callback, resource)

    %{state | callbacks: updated}
  end

  # channel:response
  defp reply_from_messages({message_id, data}, %{callbacks: callbacks} = state) do
    resource = data

    {callback, updated} = Map.pop!(callbacks, message_id)
    Callback.resolve(callback, resource)

    %{state | callbacks: updated}
  end

  # channel:response
  defp reply_with_binary(details, state) do
    reply_with_value(details, state)
  end

  # channel:response
  defp reply_with_list({message_id, list}, %{callbacks: callbacks, catalog: catalog} = state)
       when is_list(list) do
    resource = Enum.map(list, fn %{guid: guid} -> Catalog.get(catalog, guid) end)

    {callback, updated} = Map.pop!(callbacks, message_id)
    Callback.resolve(callback, resource)

    %{state | callbacks: updated}
  end

  # channel:response
  defp reply_with_value({message_id, value}, %{callbacks: callbacks} = state) do
    resource = value

    {callback, updated} = Map.pop!(callbacks, message_id)
    Callback.resolve(callback, resource)

    %{state | callbacks: updated}
  end

  # defp hydrate() do
  # end
end
