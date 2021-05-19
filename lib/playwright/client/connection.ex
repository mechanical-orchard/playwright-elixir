defmodule Playwright.Client.Connection do
  require Logger

  use GenServer
  alias Playwright.ChannelOwner.Root
  alias Playwright.Client.Transport

  # API
  # ---------------------------------------------------------------------------

  defstruct(root: nil, guid_map: %{}, transport: nil, message_index: 0, messages: %{})

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def await_message(connection, message, tries \\ 10)

  def await_message(connection, message, tries) do
    message_index = GenServer.call(connection, :increment)
    GenServer.cast(connection, {:send_message, message, message_index})
    await_message(connection, message, tries, message_index)
  end

  def await_message(_connection, _message, 0, _), do: raise("No more tries!")

  def await_message(connection, message, tries, message_index) do
    case GenServer.call(connection, {:get_message, message_index}) do
      nil ->
        :timer.sleep(50)
        Logger.info("Awaiting message no. #{inspect(message_index)}")
        await_message(connection, message, tries - 1, message_index)

      msg ->
        msg
    end
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

  def handle_call({:get_guid_from_map, guid}, _, state) do
    {:reply, state.guid_map[guid], state}
  end

  def handle_call({:get_message, id}, _, state) do
    # TODO: delete the one we found from `state.messages`.
    # Logger.info("get_message... Looking for #{inspect(id)} in #{inspect(state.messages)}")
    {:reply, state.messages[id], state}
  end

  def handle_call(:increment, _, state) do
    state = Map.put(state, :message_index, state.message_index + 1)
    {:reply, state.message_index, state}
  end

  def handle_call(:show, _, state) do
    {:reply, Map.keys(state.guid_map), state}
  end

  def handle_cast({:send_message, message, message_index}, state) do
    payload = Jason.encode!(Map.put(message, :id, message_index))

    case Transport.WebSocket.send_message(state.transport, payload) do
      :ok ->
        # Logger.info("send_message success for message #{inspect(message_index)}")
        :ok

      {:error, reason} ->
        Logger.error(inspect(reason))
    end

    {:noreply, Map.put(state, message_index, message_index)}
  end

  def handle_info({:register, {guid, item}}, state) do
    {:noreply, %__MODULE__{state | guid_map: Map.put(state.guid_map, guid, item)}}
  end

  def handle_info({:process_frame, {:text, json}}, state) do
    {:ok, data} = Jason.decode(json)
    {:noreply, process_json(data, state)}
  end

  # private
  # ---------------------------------------------------------------------------

  defp channel_owner(%{"type" => type}) do
    String.to_existing_atom("Elixir.Playwright.ChannelOwner.#{type}")
  end

  # TODO: get the "deep atomize" from Apex, so we're not using string kyeys.
  defp process_json(%{"id" => id} = data, state) do
    Logger.info("processing JSON of requested object, #{inspect(id)}, and data: #{inspect(data)}")
    Map.put(state, :messages, Map.put(state.messages, id, data))
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
