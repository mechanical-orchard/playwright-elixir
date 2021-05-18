defmodule Playwright.Client.Transport do
  require Logger

  defmodule WebSocket do
    use WebSockex

    # API
    # ---------------------------------------------------------------------------

    defstruct(connection: nil)

    def start_link([ws_endpoint, connection]) do
      Logger.info("Transport.start_link w/ connection: #{inspect(connection)}")
      WebSockex.start_link(ws_endpoint, __MODULE__, %__MODULE__{connection: connection})
    end

    def start_link!(args) do
      Logger.info("start_link! with args #{inspect(args)}")
      {:ok, pid} = start_link(args)
      pid
    end

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
