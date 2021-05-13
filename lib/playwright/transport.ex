defmodule Playwright.Transport do
  require Logger

  use WebSockex

  # API
  # ---------------------------------------------------------------------------

  defstruct(incoming: [])

  def start_link(ws_endpoint) do
    WebSockex.start_link(ws_endpoint, __MODULE__, %__MODULE__{})
  end

  def poll(self) do
    :ok = WebSockex.cast(self, {:poll, self()})

    receive do
      {:text, msg} ->
        msg
        # after
        #   200 -> raise "Failed to poll"
    end
  end

  # def send(self, {:text, message}) do
  #   WebSockex.send_frame(self, {:text, message})
  # end

  # @impl
  # ---------------------------------------------------------------------------

  @impl WebSockex
  def handle_connect(_conn, state) do
    # Logger.info(
    #   "Connected <self: #{inspect(self())}, conn: #{inspect(conn)}, state: #{inspect(state)}>"
    # )

    {:ok, state}
  end

  @impl WebSockex
  def handle_cast({:poll, pid}, state) do
    case state.incoming do
      [head | tail] ->
        state = Map.put(state, :incoming, tail)
        send(pid, head)
        {:ok, state}

      [] ->
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_frame(frame, state) do
    # Logger.info(
    #   "RECV <self: #{inspect(self())}, frame: #{inspect(frame)}, state: #{inspect(state)}>"
    # )

    incoming = state.incoming ++ [frame]
    state = Map.put(state, :incoming, incoming)

    {:ok, state}
  end

  @impl WebSockex
  def handle_info(message, state) do
    Logger.info(
      "INFO <self: #{inspect(self())}, message: #{inspect(message)}, state: #{inspect(state)}>"
    )

    {:ok, state}
  end
end
