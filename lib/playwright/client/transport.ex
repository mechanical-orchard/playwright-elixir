defmodule Playwright.Client.Transport do
  require Logger

  defmodule WebSocket do
    use WebSockex

    # API
    # ---------------------------------------------------------------------------

    defstruct(connection: nil)

    def start_link([ws_endpoint, connection]) do
      Logger.info("Transport.start_link w/ connection: #{inspect(connection)}")

      WebSockex.start_link(ws_endpoint, __MODULE__, %__MODULE__{connection: connection}, [
        {:socket_recv_timeout, 120_000}
      ])
    end

    def start_link!(args) do
      Logger.info("start_link! with args #{inspect(args)}")
      {:ok, pid} = start_link(args)
      pid
    end

    def send_message(pid, message) do
      Logger.info("Transport send_message: #{inspect(message)} for transport #{inspect(pid)}")
      WebSockex.send_frame(pid, {:text, message})
    end

    # @impl
    # ---------------------------------------------------------------------------

    @impl WebSockex
    def handle_cast({:send, {type, msg} = frame}, state) do
      IO.puts("Sending #{type} frame with payload: #{msg}")
      {:reply, frame, state}
    end

    @impl WebSockex
    def handle_connect(_conn, state) do
      # Logger.info(
      #   "Connected <self: #{inspect(self())}, conn: #{inspect(conn)}, state: #{inspect(state)}>"
      # )

      {:ok, state}
    end

    @impl WebSockex
    def handle_frame(frame, state) do
      # Logger.info(
      #   "RECV <self: #{inspect(self())}, frame: #{inspect(frame)}, state: #{inspect(state)}>"
      # )

      send(state.connection, {:process_frame, frame})

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
end
