defmodule Playwright.Chromium do
  use GenServer
  alias Playwright.WebSocketClient

  defstruct(websocket_pid: nil)

  # API
  # ---------------------------------------------------------------------------

  @type connect_options :: [connect_option]
  @type connect_option ::
          {:ws_endpoint, String.t()}

  @doc """
  Starts the Chromium `Process` with a WebSocket connection to Playwright.

  Returns ...
  """
  def connect(pid, connect_options \\ []) do
    GenServer.call(pid, {:connect, connect_options})
  end

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, :ok)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def new_page(pid) do
  end

  # @impl (GenServer callbacks)
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call({:connect, connect_options}, _from, state) do
    url = Keyword.get(connect_options, :ws_endpoint)

    case WebSocketClient.start_link(url) do
      {:ok, websocket_pid} ->
        state = %__MODULE__{state | websocket_pid: websocket_pid}
        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:stop, _from, state) do
    IO.inspect(state.websocket_pid, label: "[code] about to stop")
    # Agent.stop(state.websocket_pid)
    Process.exit(state.websocket_pid, :kill)
    {:reply, :ok, state}
  end
end
