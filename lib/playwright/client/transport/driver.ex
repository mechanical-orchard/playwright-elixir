defmodule Playwright.Client.Transport.Driver do
  @moduledoc false
  use GenServer
  alias Playwright.Connection
  alias Playwright.Transport.DriverFrame
  require Logger

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

    messages |> Enum.each(fn message -> post(state.connection, message) end)

    {:noreply, %{state | buffer: buffer, remaining: remaining}}
  end

  def handle_info({_port, {:exit_status, status}}, state) do
    Logger.error("[transport@#{inspect(self())}] playwright driver exited with status: #{inspect(status)}")
    {:stop, :port_closed, state}
  end

  # private
  # --------------------------------------------------------------------------

  def post(connection, json) do
    Connection.recv(connection, {:text, json})
  end
end
