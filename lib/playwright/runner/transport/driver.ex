defmodule Playwright.Runner.Transport.Driver do
  @moduledoc false
  # A transport for negotiating messages with the embedded Playwright `driver`
  # CLI.

  use GenServer
  require Logger
  alias Playwright.Runner.Connection
  alias Playwright.Runner.Transport.DriverMessage

  def start_link(arg) do
    # Logger.warn("Driver.start_link with args: #{inspect(arg)}")
    GenServer.start_link(__MODULE__, arg)
  end

  def start_link!({_connection, _config} = arg) do
    {:ok, pid} = start_link(arg)
    pid
  end

  def post(pid, message) do
    GenServer.cast(pid, {:post, message})
  end

  # @impl
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init({connection, config}) do
    # Logger.warn("Driver.init with connection: #{inspect(connection)} and config: #{inspect(config)}")
    cli = config.executable_path
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

  @impl GenServer
  def handle_cast({:post, message}, %{port: port} = state) do
    length = String.length(message)
    padding = <<length::utf32-little>>

    Logger.debug("SEND --> (Transport.post) message: #{inspect(Jason.decode!(message))}")
    Port.command(port, padding)
    Port.command(port, message)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {_port, {:data, data}},
        %{buffer: buffer, remaining: remaining} = state
      ) do
    %{
      frames: frames,
      remaining: remaining,
      buffer: buffer
    } = DriverMessage.parse(data, remaining, buffer, [])

    frames |> Enum.each(fn frame -> recv(state.connection, frame) end)

    {:noreply, %{state | buffer: buffer, remaining: remaining}}
  end

  @impl GenServer
  def handle_info({_port, {:exit_status, status}}, state) do
    Logger.error("[transport@#{inspect(self())}] playwright driver exited with status: #{inspect(status)}")
    {:stop, :port_closed, state}
  end

  # private
  # ----------------------------------------------------------------------------

  defp recv(connection, json) do
    Logger.debug("<--- RECV (Transport.recv) message: #{inspect(Jason.decode!(json))}")
    Connection.recv(connection, {:text, json})
  end
end
