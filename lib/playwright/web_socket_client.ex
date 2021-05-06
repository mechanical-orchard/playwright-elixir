defmodule Playwright.WebSocketClient do
  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, nil)
  end

  # @impl seen
  # ---------------------------------------------------------------------------
  @impl WebSockex
  def handle_connect(conn, state) do
    IO.puts("\n--> MATCHED handle_connect(conn: #{inspect(conn)}, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  def handle_frame({:text, text}, state) do
    IO.puts("\n--> MATCHED handle_frame(text: #{inspect(text)}, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  def handle_frame(frame, state) do
    IO.puts("\n--> GENERIC handle_frame(frame: #{inspect(frame)}, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  def terminate({:remote, :closed}, state) do
    IO.puts("\n--> MATCHED terminate(remote closed, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  def terminate(reason, state) do
    IO.puts("\n--> GENERIC terminate(reason: #{inspect(reason)}, state: #{inspect(state)})")
    {:ok, state}
  end

  # @impl unseen thus far
  # ---------------------------------------------------------------------------
  @impl WebSockex
  def code_change(prev, state, _) do
    IO.puts("\n--> SEEKING code_change(prev: #{inspect(prev)}, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  # def handle_cast({:send, {type, msg} = frame}, state) do
  def handle_cast(msg, state) do
    IO.puts("\n--> SEEKING handle_cast(msg: #{inspect(msg)}, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  # TODO/LEARN: determine why this did not match for "reason: {:remote, :closed}"
  def handle_disconnect({:reason, reason}, state) do
    IO.puts(
      "\n--> SEEKING handle_disconnect(reason: #{inspect(reason)}, state: #{inspect(state)})"
    )

    {:ok, state}
  end

  @impl WebSockex
  # The @docs say,
  # > This callback is only invoked in the event of a connection failure. Note that it does *not* appear to occur for a connection request to a bogus endpoing (not listening on port), and the Process actually runs.
  # However, this is actually called when the remote close the connection, which could be quite handy.
  # e.g.,
  # --> GENERIC handle_disconnect(status: %{attempt_number: 1, conn: %WebSockex.Conn{cacerts: nil, conn_mod: :gen_tcp, extra_headers: [], host: "localhost", insecure: true, path: "/playwright", port: 3000, query: nil, resp_headers: [{"Sec-Websocket-Accept", "we/LqSB5bl+uaEl7Qs7u1awdQIc="}, {:Connection, "Upgrade"}, {:Upgrade, "websocket"}], socket: nil, socket_connect_timeout: 6000, socket_recv_timeout: 5000, ssl_options: nil, transport: :tcp}, reason: {:remote, :closed}}, state: nil)
  def handle_disconnect(status, state) do
    IO.puts(
      "\n--> GENERIC handle_disconnect(status: #{inspect(status)}, state: #{inspect(state)})"
    )

    {:ok, state}
  end

  @impl WebSockex
  def handle_info(msg, state) do
    IO.puts("\n--> SEEKING handle_info(msg: #{inspect(msg)}, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  def handle_ping(frame, state) do
    IO.puts("\n--> SEEKING handle_ping(frame: #{inspect(frame)}, state: #{inspect(state)})")
    {:ok, state}
  end

  @impl WebSockex
  def handle_pong(frame, state) do
    IO.puts("\n--> SEEKING handle_pong(frame: #{inspect(frame)}, state: #{inspect(state)})")
    {:ok, state}
  end
end
