defmodule Playwright.Client.Transport.WebSocket do
  @moduledoc false
  use WebSockex
  alias Playwright.Connection

  # API
  # ---------------------------------------------------------------------------

  defstruct(connection: nil)

  def start_link([ws_endpoint, connection]) do
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
    Connection.recv(connection, frame)

    {:ok, state}
  end
end
