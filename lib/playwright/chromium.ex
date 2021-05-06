defmodule Playwright.Chromium do
  use GenServer
  alias Playwright.WebSocketClient

  # API
  # ---------------------------------------------------------------------------

  @type connect_options :: [connect_option]
  @type connect_option ::
          {:ws_endpoint, String.t()}

  @doc """
  Starts the Chromium `Process` with a WebSocket connection to Playwright.

  Returns ...
  """
  @spec connect(connect_options()) :: {:ok, pid()} | {:error, any()}
  def connect(connect_options \\ []) do
    case GenServer.start_link(__MODULE__, :ok) do
      {:ok, pid} ->
        # IO.inspect(pid, label: "PID for Chromium.connect --> GenServer.start_link")
        GenServer.call(pid, {:connect, connect_options})
        {:ok, pid}
    end
  end

  # @impl (GenServer callbacks)
  # ---------------------------------------------------------------------------

  @impl GenServer
  @spec init(any) :: {:ok, nil}
  def init(_) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:connect, connect_options}, _from, nil) do
    url = Keyword.get(connect_options, :ws_endpoint)

    case WebSocketClient.start_link(url) do
      {:ok, pid} ->
        IO.inspect(pid, label: "PID for WebSocket.start_link")
        {:reply, {:ok, pid}, nil}

      error ->
        {:reply, error, nil}
    end
  end
end
