defmodule Playwright.Client.Connection do
  require Logger

  use GenServer
  alias Playwright.ChannelOwner.Root
  alias Playwright.Client.Transport

  # API
  # ---------------------------------------------------------------------------

  defstruct(root: nil, guid_map: nil, transport: nil)

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

  def send_message(connection, message) do
    GenServer.cast(connection, {:send_message, Jason.encode!(message)})
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init([transport, [ws_endpoint, _opts]]) do
    pid = self()
    Logger.info("Connection.init w/ self: #{inspect(pid)}")

    # WARN: this is potentially racy: the websocket must be opened *after* `root` is created.
    connection = %__MODULE__{
      guid_map: %{},
      root: Root.new(pid),
      transport: transport.start_link!([ws_endpoint, pid])
    }

    {:ok, connection}
  end

  def handle_call({:get_guid_from_map, guid}, _, state) do
    {:reply, state.guid_map[guid], state}
  end

  def handle_call(:show, _, state) do
    {:reply, Map.keys(state.guid_map), state}
  end

  def handle_cast({:send_message, message}, state) do
    case Transport.WebSocket.send_message(state.transport, message) do
      :ok ->
        Logger.info("send_message success")

      {:error, reason} ->
        Logger.error(inspect(reason))
    end

    {:noreply, state}
  end

  def handle_info({:register, {guid, item}}, state) do
    {:noreply, %__MODULE__{state | guid_map: Map.put(state.guid_map, guid, item)}}
  end

  def handle_info({:process_frame, {:text, json}}, state) do
    {:ok, data} = Jason.decode(json)

    process_json(data, state)
    {:noreply, state}
  end

  # private
  # ---------------------------------------------------------------------------

  defp channel_owner(%{"type" => type}) do
    String.to_existing_atom("Elixir.Playwright.ChannelOwner.#{type}")
  end

  # TODO: get the "deep atomize" from Apex, so we're not using string kyeys.
  # defp process_json(%{"id" => id} = data) do
  #   Logger.info("processing JSON with a known object, #{inspect(id)}, and data: #{inspect(data)}")
  # end

  defp process_json(
         %{
           "guid" => parent_guid,
           "method" => "__create__",
           "params" => params
         },
         state
       ) do
    apply(channel_owner(params), :new, [state.guid_map[parent_guid], params])
  end

  defp process_json(%{"method" => "__dispose__"} = data, _state) do
    Logger.info("processing JSON to dispose: #{inspect(data)}")
  end

  defp process_json(data, _state) do
    Logger.info("processing JSON of some other kind: #{inspect(data)}")
  end
end
