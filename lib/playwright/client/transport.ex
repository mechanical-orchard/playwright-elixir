defmodule Playwright.Client.Transport do
  require Logger

  defmodule Driver do
    use GenServer
    alias Playwright.Transport.DriverFrame

    # API
    # -------------------------------------------------------------------------

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def start_link!(args) do
      {:ok, pid} = start_link(args)
      pid
    end

    def send_message(pid, message) do
      GenServer.cast(pid, {:send_message, message})
      :ok
    end

    # @impl
    # -------------------------------------------------------------------------

    def init([driver_path, connection]) do
      cli = driver_path
      cmd = "run-driver"

      port = Port.open({:spawn, "#{cli} #{cmd}"}, [:binary, :exit_status])

      {
        :ok,
        %{
          connection: connection,
          port: port,
          remaining: 0,
          buffer: ""
        }
      }
    end

    def handle_cast({:send_message, message}, %{port: port} = state) do
      length = String.length(message)
      padding = <<length::utf32-little>>

      Port.command(port, padding)
      Port.command(port, message)

      {:noreply, state}
    end

    def handle_info(
          {_port, {:data, data}},
          %{buffer: buffer, remaining: remaining} = state
        ) do
      %{
        messages: messages,
        remaining: remaining,
        buffer: buffer
      } = DriverFrame.parse_frame(data, remaining, buffer, [])

      messages |> Enum.map(fn message -> post(state.connection, message) end)

      {:noreply, %{state | buffer: buffer, remaining: remaining}}
    end

    def handle_info({_port, {:exit_status, status}}, state) do
      status |> IO.inspect(label: "exit")
      {:noreply, %{state | exit_status: status}}
    end

    # private
    # --------------------------------------------------------------------------

    def post(connection, json) do
      data = Jason.decode!(json)
      send(connection, {:process_frame, {:data, data}})
    end
  end

  defmodule WebSocket do
    use WebSockex

    # API
    # ---------------------------------------------------------------------------

    defstruct(connection: nil)

    def start_link([ws_endpoint, connection]) do
      Logger.info("WebSocket connecting to #{inspect(ws_endpoint)}")

      WebSockex.start_link(ws_endpoint, __MODULE__, %__MODULE__{connection: connection}, [
        {:socket_recv_timeout, 120_000}
      ])
    end

    def start_link!(args) do
      {:ok, pid} = start_link(args)
      pid
    end

    def send_message(pid, message) do
      WebSockex.send_frame(pid, {:text, message})
    end

    # @impl
    # ---------------------------------------------------------------------------

    @impl WebSockex
    def handle_connect(_conn, state) do
      {:ok, state}
    end

    @impl WebSockex
    def handle_frame(frame, %{connection: connection} = state) do
      send(connection, {:process_frame, frame})
      {:ok, state}
    end
  end
end
