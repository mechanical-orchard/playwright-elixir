defmodule Playwright.Socket do
  use WebSockex

  # API
  # ---------------------------------------------------------------------------

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, nil)
  end

  # iex> Playwright.post(pid, "laaaa")
  #
  # undefined:1
  # laaaa
  # ^

  # SyntaxError: Unexpected token l in JSON at position 0
  #     at JSON.parse (<anonymous>)
  #     at WebSocket.<anonymous> (/usr/src/app/node_modules/playwright-core/lib/browserServerImpl.js:114:38)
  #     at WebSocket.emit (events.js:315:20)
  #     at Receiver.receiverOnMessage (/usr/src/app/node_modules/playwright-core/node_modules/ws/lib/websocket.js:825:20)
  #     at Receiver.emit (events.js:315:20)
  #     at Receiver.dataMessage (/usr/src/app/node_modules/playwright-core/node_modules/ws/lib/receiver.js:437:14)
  #     at Receiver.getData (/usr/src/app/node_modules/playwright-core/node_modules/ws/lib/receiver.js:367:17)
  #     at Receiver.startLoop (/usr/src/app/node_modules/playwright-core/node_modules/ws/lib/receiver.js:143:22)
  #     at Receiver._write (/usr/src/app/node_modules/playwright-core/node_modules/ws/lib/receiver.js:78:10)
  #     at writeOrBuffer (internal/streams/writable.js:358:12)
  def post(socket, message) do
    WebSockex.send_frame(socket, {:text, message})
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
end
