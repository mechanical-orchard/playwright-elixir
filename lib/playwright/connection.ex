defmodule Playwright.Connection do
  @moduledoc false
  require Logger

  use GenServer

  alias Playwright.ChannelMessage
  alias Playwright.ChannelOwner.Root
  alias Playwright.Extra

  # API
  # ----------------------------------------------------------------------------

  # Transport.Driver | Transport.WebSocket
  @type transport_module :: module()
  @type transport_config :: {transport_module, [term()]}

  defstruct(
    catalog: %{},
    channel_message_callers: %{},
    channel_messages: %{},
    messages: %{pending: %{}},
    queries: %{},
    transport: %{}
  )

  # messages -> pending, awaiting, ...

  @spec start_link([transport_config]) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  # API: items...

  def wait_for_channel_messages(connection, type) do
    GenServer.call(connection, {:get_channel_messages, type})
  end

  def get(connection, {:guid, _guid} = item) do
    GenServer.call(connection, {:get, item})
  end

  def find(connection, attributes, default \\ []) do
    GenServer.call(connection, {:find, attributes, default})
  end

  # API: messages...

  @spec post(pid(), {:data, ChannelMessage.t()}) :: term()
  def post(connection, {:data, _data} = message) do
    GenServer.call(connection, {:post, message})
  end

  def recv(connection, {:text, _json} = message) do
    GenServer.cast(connection, {:recv, message})
  end

  # @impl
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init([{transport_module, config}]) do
    {:ok,
     %__MODULE__{
       catalog: %{
         "Root" => Root.new(self())
       },
       transport: %{
         mod: transport_module,
         pid: transport_module.start_link!([self()] ++ config)
       }
     }}
  end

  @impl GenServer
  def handle_call({:get_channel_messages, type}, from, state) do
    if Map.has_key?(state.channel_messages, type) do
      {:reply, state.channel_messages[type], state}
    else
      {:noreply, %{state | channel_message_callers: Map.put(state.channel_message_callers, type, from)}}
    end
  end

  @impl GenServer
  def handle_call({:find, attrs, default}, _from, %{catalog: catalog} = state) do
    case select(Map.values(catalog), attrs, []) do
      [] ->
        {:reply, default, state}

      result ->
        {:reply, result, state}
    end
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
  def handle_call({:post, {:data, data}}, from, %{messages: messages, queries: queries, transport: transport} = state) do
    queries = Map.put(queries, data.id, from)

    messages =
      Map.merge(messages, %{
        pending: Map.put(messages.pending, data.id, data)
      })

    transport.mod.post(transport.pid, Jason.encode!(data))

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
    _recv_(Jason.decode!(json) |> Extra.Map.deep_atomize_keys(), state)
  end

  defp _recv_(%{id: message_id, result: result}, state) do
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

  defp _recv_(%{id: message_id} = data, state) do
    reply_from_messages({message_id, data}, state)
  end

  defp _recv_(%{guid: ""} = data, state) do
    _recv_(Map.put(data, :guid, "Root"), state)
  end

  defp _recv_(
         %{guid: parent_guid, method: "__create__", params: params},
         %{catalog: catalog} = state
       ) do
    item = apply(resource(params), :new, [catalog[parent_guid], params])

    %{state | catalog: _put_(item, state)}
    |> update_channel_messages(item)
  end

  defp _recv_(%{guid: guid, method: "__dispose__"}, %{catalog: catalog} = state) do
    %{state | catalog: _del_(guid, catalog)}
  end

  defp _recv_(_data, state) do
    # Logger.debug("_recv_ other   :: #{inspect(data)}")
    state
  end

  defp resource(%{type: type}) do
    try do
      String.to_existing_atom("Elixir.Playwright.ChannelOwner.#{type}")
    rescue
      ArgumentError ->
        message = "ChannelOwner of type #{inspect(type)} is not yet defined"
        Logger.debug(message)
        exit(message)
    end
  end

  defp reply_from_catalog({message_id, guid}, %{catalog: catalog, messages: messages, queries: queries} = state) do
    {message, pending} = Map.pop!(messages.pending, message_id)
    {from, queries} = Map.pop!(queries, message_id)

    item =
      catalog[guid]
      |> Map.merge(message.locals || %{})

    GenServer.reply(from, item)

    %{state | catalog: Map.put(catalog, guid, item), messages: Map.put(messages, :pending, pending), queries: queries}
  end

  defp reply_from_messages({message_id, data}, %{catalog: _catalog, messages: messages, queries: queries} = state) do
    {message, pending} = Map.pop!(messages.pending, message_id)
    {from, queries} = Map.pop!(queries, message_id)
    GenServer.reply(from, Map.merge(message, data))

    %{state | messages: Map.put(messages, :pending, pending), queries: queries}
  end

  defp reply_with_binary(details, state) do
    reply_with_value(details, state)
  end

  defp reply_with_list({message_id, list}, %{catalog: catalog, messages: messages, queries: queries} = state)
       when is_list(list) do
    data = list |> Enum.map(fn %{guid: guid} -> catalog[guid] end)
    {_message, pending} = Map.pop!(messages.pending, message_id)
    {from, queries} = Map.pop!(queries, message_id)
    GenServer.reply(from, data)
    %{state | messages: Map.put(messages, :pending, pending), queries: queries}
  end

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

  defp select([head | tail], %{guid: guid} = attrs, result)
       when head.guid == guid do
    select(tail, attrs, result ++ [head])
  end

  defp select([_head | tail], attrs, result) do
    select(tail, attrs, result)
  end

  defp update_channel_messages(state, item) do
    channel_messages =
      Map.update(state.channel_messages, item.type, [item], fn
        items -> [item | items]
      end)

    if Map.has_key?(state.channel_message_callers, item.type) do
      {caller, channel_message_callers} = Map.pop(state.channel_message_callers, item.type)
      GenServer.reply(caller, channel_messages[item.type])
      %{state | channel_messages: channel_messages, channel_message_callers: channel_message_callers}
    else
      %{state | channel_messages: channel_messages}
    end
  end
end
