defmodule Playwright.Client.Connection do
  require Logger

  use GenServer
  alias Playwright.ChannelOwner.Root
  # alias Playwright.Client.Connection

  # API
  # ---------------------------------------------------------------------------

  defstruct(root: nil, registry: nil, transport: nil)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init([transport, [ws_endpoint, _opts]]) do
    pid = self()
    Logger.info("Connection.init w/ self: #{inspect(pid)}")

    # WARN: this is potentially racy: the websocket must be opened *after* `root` is created.
    connection = %__MODULE__{
      registry: %{},
      root: Root.new(pid),
      transport: transport.start_link!([ws_endpoint, pid])
    }

    {:ok, connection}
  end

  # def handle_call({:connect, args}, _, state) do
  #   {:reply, transport, state}
  # end

  def handle_call(:show, _, state) do
    {:reply, Map.keys(state.registry), state}
  end

  def handle_call({:wait_for, guid}, _, state) do
    {:reply, fetch(guid, state), state}
  end

  def handle_info({:register, {guid, item}}, state) do
    {:noreply, %__MODULE__{state | registry: Map.put(state.registry, guid, item)}}
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

  defp fetch(guid, state) do
    case state.registry[guid] do
      nil ->
        :timer.sleep(200)

        Logger.info(
          "Attempting to fetch #{inspect(guid)} from #{inspect(Map.keys(state.registry))}"
        )

        fetch(guid, state)

      object ->
        object
    end
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
    apply(channel_owner(params), :new, [state.registry[parent_guid], params])
  end

  defp process_json(%{"method" => "__dispose__"} = data, _state) do
    Logger.info("processing JSON to dispose: #{inspect(data)}")
  end

  defp process_json(data, _state) do
    Logger.info("processing JSON of some other kind: #{inspect(data)}")
  end
end
