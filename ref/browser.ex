defmodule Playwright.Ref.Browser do
  use GenServer
  alias Playwright.WebSocketClient

  @type connect_options :: [connect_option]

  @type connect_option ::
          {:ws_endpoint, String.t()}

  @doc """
  Starts the Browser process without connecting to Playwright.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc """
  Makes the connection to Playwright.
  """
  @spec connect(pid(), connect_options()) :: :ok | {:error, any()}
  def connect(pid, connect_options \\ []) do
    GenServer.call(pid, {:connect, connect_options})
  end

  @impl GenServer
  def init(_) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:connect, connect_options}, _from, state) do
    url = Keyword.get(connect_options, :ws_endpoint, "ws://localhost:3000/playwright")

    case WebSocketClient.start_link(url) do
      {:ok, pid} ->
        {:reply, :ok, pid}

      error ->
        {:reply, error, state}
    end
  end
end
