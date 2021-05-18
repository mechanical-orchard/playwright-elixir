defmodule Playwright.Client.Connection do
  require Logger

  use GenServer
  alias Playwright.ChannelOwner.Root
  alias Playwright.Client.Connection

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
    {:ok, registry} = Connection.Registry.start_link()

    connection = %__MODULE__{
      registry: registry,
      root: Root.new(pid),
      transport: transport.start_link!([ws_endpoint, pid])
    }

    {:ok, connection}
  end

  # def handle_call({:connect, args}, _, state) do
  #   {:reply, transport, state}
  # end

  def handle_call(:show, _, state) do
    send(state.registry, {:keys, self()})

    receive do
      {:registry_all, value} ->
        {:reply, value, state}
    end
  end

  def handle_call({:wait_for, guid}, _, state) do
    Logger.info("Waiting for #{inspect(guid)} to be found in state: #{inspect(state)}")

    result = fetch(guid, state)
    Logger.info("...after waiting for #{inspect(guid)}, we ended up with #{inspect(result)}")
    {:reply, result, state}
  end

  defp fetch(guid, state) do
    send(state.registry, {:get, guid, self()})

    receive do
      {:registry_get, nil} ->
        Logger.info("FETCH: trying again for #{inspect(guid)}")
        :timer.sleep(500)
        fetch(guid, state)

      {:registry_get, result} ->
        Logger.info("FETCH: guid = #{inspect(result)}")
        result
    end
  end

  def handle_info({:register, {guid, item}}, state) do
    send(state.registry, {:put, guid, item})

    {:noreply, state}
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
    send(state.registry, {:get, parent_guid, self()})

    receive do
      {:registry_get, parent} ->
        Logger.info("PROCESS_JSON - #{inspect(parent)}")
        apply(channel_owner(params), :new, [parent, params])
    end
  end

  defp process_json(%{"method" => "__dispose__"} = data, _state) do
    Logger.info("processing JSON to dispose: #{inspect(data)}")
  end

  defp process_json(data, _state) do
    Logger.info("processing JSON of some other kind: #{inspect(data)}")
  end

  defmodule Registry do
    require Logger

    def start_link do
      Task.start_link(fn -> loop(%{}) end)
    end

    defp loop(map) do
      receive do
        {:keys, caller} ->
          send(caller, {:registry_all, Map.keys(map)})
          loop(map)

        {:get, key, caller} ->
          send(caller, {:registry_get, Map.get(map, key)})
          loop(map)

        {:put, key, item} ->
          loop(Map.put(map, key, item))
      end
    end
  end
end
