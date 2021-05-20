defmodule Playwright.Client.Connection do
  require Logger

  use GenServer
  alias Playwright.ChannelOwner.Root
  alias Playwright.Client.Transport

  # API
  # ---------------------------------------------------------------------------

  defstruct(
    root: nil,
    guid_map: %{},
    transport: nil,
    message_index: 0,
    messages: %{},
    queries: %{}
  )

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def get(connection, guid) do
    GenServer.call(connection, {:get, guid})
  end

  def has(connection, guid) do
    GenServer.call(connection, {:has, guid})
  end

  def post(connection, message) do
    i = GenServer.call(connection, :increment)

    try do
      case GenServer.call(connection, {:post, message, i}) |> parse_response do
        {:guid, guid} ->
          get(connection, guid)

        {:value, value} ->
          value

        nil ->
          nil

        :ok ->
          :ok
      end
    catch
      :exit, value ->
        Logger.error("Connection.post timed out with #{inspect(value)}")
        :error
    end
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init([transport, [ws_endpoint, _opts]]) do
    pid = self()

    # WARN: this is potentially racy: the websocket must be opened *after* `root` is created.
    connection = %__MODULE__{
      root: Root.new(pid),
      transport: transport.start_link!([ws_endpoint, pid])
    }

    {:ok, connection}
  end

  def handle_call(
        {:get, guid},
        from,
        %{
          guid_map: guid_map,
          queries: queries
        } = state
      ) do
    case guid_map[guid] do
      nil ->
        queries = Map.put(queries, guid, from)
        {:noreply, Map.put(state, :queries, queries)}

      result ->
        {:reply, result, state}
    end
  end

  def handle_call({:has, guid}, _, %{guid_map: guid_map} = state) do
    {:reply, guid_map[guid] != nil, state}
  end

  def handle_call(
        {:post, message, index},
        from,
        %{transport: transport, queries: queries} = state
      ) do
    payload = Jason.encode!(Map.put(message, :id, index))
    queries = Map.put(queries, index, from)

    case Transport.WebSocket.send_message(transport, payload) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error(inspect(reason))
    end

    {:noreply, Map.put(state, :queries, queries)}
  end

  def handle_call({:get_guid_from_map, guid}, _, state) do
    {:reply, state.guid_map[guid], state}
  end

  def handle_call(:increment, _, state) do
    state = Map.put(state, :message_index, state.message_index + 1)
    {:reply, state.message_index, state}
  end

  def handle_call(:show, _, state) do
    {:reply, Map.keys(state.guid_map), state}
  end

  def handle_info({:process_frame, {:text, json}}, state) do
    {:ok, data} = Jason.decode(json)
    {:noreply, process_json(data, state)}
  end

  def handle_info({:register, {guid, item}}, state) do
    {:noreply, %__MODULE__{state | guid_map: Map.put(state.guid_map, guid, item)}}
  end

  # private
  # ---------------------------------------------------------------------------

  defp channel_owner(%{"type" => type}) do
    String.to_existing_atom("Elixir.Playwright.ChannelOwner.#{type}")
  end

  # TODO:
  # - Probably add "type" to the result tuple as well.
  # - Check other implementations to double-check that the `[] -> nil` is appropriate.
  defp parse_response(%{"result" => result}) do
    case Map.to_list(result) do
      [{"value", value}] ->
        {:value, value}

      [{_key, %{"guid" => guid}}] ->
        {:guid, guid}

      [] ->
        nil
    end
  end

  defp parse_response(%{"id" => _id}) do
    :ok
  end

  # TODO:
  # - Get the "deep atomize" from Apex, so we're not using string kyeys.
  defp process_json(%{"id" => id} = data, %{queries: queries} = state) do
    # Logger.info("processing JSON of requested object, #{inspect(id)}, and data: #{inspect(data)}")

    {from, queries} = Map.pop(queries, id)
    GenServer.reply(from, data)

    Map.put(state, :queries, queries)
  end

  defp process_json(
         %{
           "guid" => parent_guid,
           "method" => "__create__",
           "params" => params
         },
         %{queries: queries} = state
       ) do
    instance = apply(channel_owner(params), :new, [state.guid_map[parent_guid], params])
    # Logger.debug("processing JSON to create: #{inspect(parent_guid)}; #{inspect(params)}")

    case Map.pop(queries, _guid = params["guid"], nil) do
      {nil, _queries} ->
        state

      {from, queries} ->
        GenServer.reply(from, instance)
        Map.put(state, :queries, queries)
    end
  end

  # TODO:
  #
  # %{
  #   "guid" => "page@fb4b365e072903e38c52b75d3f553519",
  #   "method" => "__dispose__",
  #   "params" => %{}
  # }
  defp process_json(%{"method" => "__dispose__"} = data, %{guid_map: guid_map} = state) do
    # Logger.debug("processing JSON to dispose: #{inspect(data)}")

    {_disposed, guid_map} = Map.pop(guid_map, data["guid"])
    Map.put(state, :guid_map, guid_map)
  end

  # TODO:
  #
  # %{
  #   "guid" => "browser-context@751332afa7a75f63835b7ae13a4952cc",
  #   "method" => "page",
  #   "params" => %{"page" => %{"guid" => "page@4f82dd5ce2a2ccbe68aa73b0d1f0a85d"}}
  # }
  #
  # %{
  #   "guid" => "frame@730ea5a5d470d1264eda6aa5defb067a",
  #   "method" => "loadstate",
  #   "params" => %{"add" => "networkidle"}
  # }
  #
  # %{
  #   "guid" => "page@fb4b365e072903e38c52b75d3f553519",
  #   "method" => "close",
  #   "params" => %{}
  # }

  # %{"guid" => "frame@df2dab614bea90efdcbb9e91f022d631", "method" => "navigated", "params" => %{"name" => "", "newDocument" => %{"request" => %{"guid" => "request@3d881c11e21b87c30855c4742951e4bd"}}, "url" => "https://www.google.com/"}}
  # %{"guid" => "page@513a93931043b049a507f0885b56d0dd", "method" => "requestFinished", "params" => %{"request" => %{"guid" => "request@3d881c11e21b87c30855c4742951e4bd"}, "responseEndTiming" => 184.697}}

  defp process_json(_data, state) do
    # Logger.debug("processing JSON of some other kind: #{inspect(data)}")
    state
  end
end
