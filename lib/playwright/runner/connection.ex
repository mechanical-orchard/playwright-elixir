defmodule Playwright.Runner.Connection do
  @moduledoc false
  require Logger

  use GenServer

  alias Playwright.Extra
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Root
  alias Playwright.Runner.Transport

  # API
  # ----------------------------------------------------------------------------

  @type transport_module :: module()
  @type transport_config :: {transport_module, [term()]}

  defstruct(
    catalog: %{},
    handlers: %{},
    messages: %{pending: %{}},
    queries: %{},
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
       catalog: %{
         "Root" => Root.new(self())
       },
       transport: Transport.connect(transport_module, [self()] ++ config)
     }}
    #  catalog: Catalog.open(...)
  end

  @impl GenServer
  def handle_call({:get, {:guid, guid}}, from, %{catalog: catalog, queries: queries} = state) do
    case catalog[guid] do
      nil ->
        {:noreply, %{state | queries: Map.put(queries, guid, from)}}

      item ->
        {:reply, item, state}
    end
  end

  @impl GenServer
  def handle_call({:get, attrs, default}, _from, %{catalog: catalog} = state) do
    case select(Map.values(catalog), attrs, []) do
      [] ->
        {:reply, default, state}

      result ->
        {:reply, result, state}
    end
  end

  @impl GenServer
  def handle_call({:on, event, handler}, _from, %{handlers: handlers} = state) do
    updated = Map.update(handlers, event, [handler], fn existing -> [handler | existing] end)
    {:reply, :ok, %{state | handlers: updated}}
  end

  @impl GenServer
  def handle_call({:patch, {:guid, guid}, data}, _from, %{catalog: catalog} = state) do
    subject = Map.merge(catalog[guid], data)
    catalog = Map.put(catalog, guid, subject)
    {:reply, subject, %{state | catalog: catalog}}
  end

  # HERE... posting with an ID (channel:command)
  @impl GenServer
  def handle_call({:post, {:cmd, data}}, from, %{messages: messages, queries: queries, transport: transport} = state) do
    queries = Map.put(queries, data.id, from)

    messages =
      Map.merge(messages, %{
        pending: Map.put(messages.pending, data.id, data)
      })

    Transport.post(transport, Jason.encode!(data))

    {:noreply, %{state | messages: messages, queries: queries}}
  end

  @impl GenServer
  def handle_cast({:recv, {:text, json}}, state) do
    {:noreply, _recv_(json, state)}
  end

  # private
  # ----------------------------------------------------------------------------

  defp _del_(guid, catalog) do
    children = select(Map.values(catalog), %{parent: catalog[guid]}, [])

    catalog =
      children
      |> Enum.reduce(catalog, fn item, acc ->
        _del_(item.guid, acc)
      end)

    Map.delete(catalog, guid)
  end

  defp _put_(item, %{catalog: catalog, queries: queries} = state) do
    case Map.pop(queries, item.guid, nil) do
      {nil, _queries} ->
        state

      {from, queries} ->
        GenServer.reply(from, item)
        %{state | queries: queries}
    end

    Map.put(catalog, item.guid, item)
  end

  defp _recv_(json, state) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, data} ->
        _recv_(data |> Extra.Map.deep_atomize_keys(), state)

      _error ->
        raise ArgumentError, message: inspect(json: Enum.join(for <<c::utf8 <- json>>, do: <<c::utf8>>))
    end
  end

  # HERE... receiving with and ID (channel:response)
  defp _recv_(%{id: message_id, result: result}, state) do
    case Map.to_list(result) do
      [{_key, %{guid: guid}}] ->
        # if key == :element do
        #   Logger.info("RECV message for element w/ result: #{inspect(result)}")
        # else
        #   Logger.warn("RECV message for other: #{inspect(key)}")
        # end

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

  # HERE... receiving with and ID (channel:response)
  defp _recv_(%{id: message_id} = data, state) do
    reply_from_messages({message_id, data}, state)
  end

  defp _recv_(%{guid: ""} = data, state) do
    _recv_(Map.put(data, :guid, "Root"), state)
  end

  # NEXT... channel:event
  defp _recv_(
         %{guid: parent_guid, method: "__create__", params: params},
         %{catalog: catalog} = state
       ) do
    item = apply(resource(params), :new, [catalog[parent_guid], params])
    # Logger.info("received type to create: " <> params.type)

    # if params.type == "ElementHandle" do
    #   Logger.info("  ...with data: " <> inspect(params))
    # end

    # if params.type == "Frame" do
    #   Logger.info("  ...with data: " <> inspect(params))
    # end

    # if params.type == "JSHandle" do
    #   Logger.info("  ...with data: " <> inspect(params))
    # end

    %{state | catalog: _put_(item, state)}
  end

  # NEXT... channel:event
  defp _recv_(%{guid: guid, method: "__dispose__"}, %{catalog: catalog} = state) do
    Logger.debug("__dispose__ #{inspect(guid)}")
    %{state | catalog: _del_(guid, catalog)}
  end

  defp _recv_(%{guid: guid, method: method}, %{catalog: catalog, handlers: handlers} = state)
       when method in ["close"] do
    entry = catalog[guid]
    entry = Map.put(entry, :initializer, Map.put(entry.initializer, :isClosed, true))
    event = {:on, Extra.Atom.from_string(method), entry}
    handlers = Map.get(handlers, method, [])

    Enum.each(handlers, fn handler ->
      handler.(event)
    end)

    %{state | catalog: Map.put(catalog, guid, entry)}
  end

  defp _recv_(%{guid: guid, method: method, params: params}, %{catalog: catalog} = state)
       when method in ["previewUpdated"] do
    Logger.debug("preview updated for #{inspect(guid)}")
    updated = %Playwright.ElementHandle{catalog[guid] | preview: params.preview}
    %{state | catalog: Map.put(catalog, guid, updated)}
  end

  defp _recv_(%{method: method, params: %{message: %{guid: guid}}}, %{catalog: catalog, handlers: handlers} = state)
       when method in ["console"] do
    entry = catalog[guid]
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

  # HERE... handling a channel:response
  defp reply_from_catalog({message_id, guid}, %{catalog: catalog, messages: messages, queries: queries} = state) do
    {_message, pending} = Map.pop(messages.pending, message_id)
    {from, queries} = Map.pop(queries, message_id, nil)

    item = catalog[guid]

    if from do
      GenServer.reply(from, item)
    end

    %{state | catalog: Map.put(catalog, guid, item), messages: Map.put(messages, :pending, pending), queries: queries}
  end

  # HERE... handling a channel:response
  defp reply_from_messages({message_id, data}, %{catalog: _catalog, messages: messages, queries: queries} = state) do
    {message, pending} = Map.pop!(messages.pending, message_id)
    {from, queries} = Map.pop!(queries, message_id)
    GenServer.reply(from, Map.merge(message, data))

    %{state | messages: Map.put(messages, :pending, pending), queries: queries}
  end

  # HERE... handling a channel:response
  defp reply_with_binary(details, state) do
    reply_with_value(details, state)
  end

  # HERE... handling a channel:response
  defp reply_with_list({message_id, list}, %{catalog: catalog, messages: messages, queries: queries} = state)
       when is_list(list) do
    data = list |> Enum.map(fn %{guid: guid} -> catalog[guid] end)
    {_message, pending} = Map.pop!(messages.pending, message_id)
    {from, queries} = Map.pop!(queries, message_id)
    GenServer.reply(from, data)
    %{state | messages: Map.put(messages, :pending, pending), queries: queries}
  end

  # HERE... handling a channel:response
  defp reply_with_value({message_id, value}, %{messages: messages, queries: queries} = state) do
    {_message, pending} = Map.pop!(messages.pending, message_id)
    {from, queries} = Map.pop!(queries, message_id)

    GenServer.reply(from, value)

    %{state | messages: Map.put(messages, :pending, pending), queries: queries}
  end

  defp select([], _attrs, result) do
    result
  end

  defp select([head | tail], attrs, result) when head.type == "" do
    select(tail, attrs, result)
  end

  defp select([head | tail], %{parent: parent, type: type} = attrs, result)
       when head.parent.guid == parent.guid and head.type == type do
    select(tail, attrs, result ++ [head])
  end

  defp select([head | tail], %{parent: parent} = attrs, result)
       when head.parent.guid == parent.guid do
    select(tail, attrs, result ++ [head])
  end

  defp select([head | tail], %{type: type} = attrs, result)
       when head.type == type do
    select(tail, attrs, result ++ [head])
  end

  defp select([head | tail], %{guid: guid} = attrs, result)
       when head.guid == guid do
    select(tail, attrs, result ++ [head])
  end

  defp select([_head | tail], attrs, result) do
    select(tail, attrs, result)
  end
end
