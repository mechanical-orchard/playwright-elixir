defmodule Playwright.Client.Connection do
  require Logger

  use GenServer
  alias Playwright.ChannelOwner.Root
  # alias Playwright.Client.Connection
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

  def get_from_guid_map(connection, guid, tries \\ 10)

  def get_from_guid_map(_connection, _guid, 0), do: raise("No more tries!")

  def get_from_guid_map(connection, guid, tries) do
    case GenServer.call(connection, {:get_guid_from_map, guid}) do
      nil ->
        # TODO: Consider making this configurable. It's no longer really
        # needed for success, but it's nice to be gentle.
        :timer.sleep(50)
        get_from_guid_map(connection, guid, tries - 1)

      item ->
        item
    end
  end

  def post(connection, message) do
    i = GenServer.call(connection, :increment)
    GenServer.call(connection, {:post, message, i})
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init([transport, [ws_endpoint, _opts]]) do
    pid = self()
    Logger.info("Connection.init w/ self: #{inspect(pid)}")

    # WARN: this is potentially racy: the websocket must be opened *after* `root` is created.
    connection = %__MODULE__{
      root: Root.new(pid),
      transport: transport.start_link!([ws_endpoint, pid])
    }

    {:ok, connection}
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

  # TODO: get the "deep atomize" from Apex, so we're not using string kyeys.
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
         state
       ) do
    apply(channel_owner(params), :new, [state.guid_map[parent_guid], params])
    state
  end

  defp process_json(%{"method" => "__dispose__"} = data, state) do
    Logger.info("processing JSON to dispose: #{inspect(data)}")
    state
  end

  defp process_json(data, state) do
    Logger.info("processing JSON of some other kind: #{inspect(data)}")
    state
    # TODO:
    # %{
    #   "guid" => "browser-context@751332afa7a75f63835b7ae13a4952cc",
    #   "method" => "page",
    #   "params" => %{"page" => %{"guid" => "page@4f82dd5ce2a2ccbe68aa73b0d1f0a85d"}}
    # }
  end
end
