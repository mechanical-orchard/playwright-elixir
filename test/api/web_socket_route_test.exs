defmodule Playwright.WebSocketRouteTest do
  use Playwright.TestCase, transport: :driver

  alias Playwright.{Page, WebSocketRoute}

  describe "Page.route_web_socket/3" do
    test "intercepts WebSocket connections", %{assets: assets, page: page} do
      test_pid = self()

      Page.route_web_socket(page, "**/*", fn ws_route ->
        send(test_pid, {:ws_route, ws_route})
      end)

      Page.goto(page, assets.empty)

      result =
        Page.evaluate(page, """
          () => {
            return new Promise((resolve) => {
              const ws = new WebSocket('ws://localhost:9999/ws');
              ws.onopen = () => resolve('opened');
              ws.onerror = () => resolve('error');
              setTimeout(() => resolve('timeout'), 3000);
            });
          }
        """)

      assert result == "opened"
      assert_receive {:ws_route, %WebSocketRoute{}}, 1000
    end

    test "handler receives correct URL", %{assets: assets, page: page} do
      test_pid = self()

      Page.route_web_socket(page, "**/my-websocket", fn ws_route ->
        send(test_pid, {:url, WebSocketRoute.url(ws_route)})
      end)

      Page.goto(page, assets.empty)

      Page.evaluate(page, """
        () => {
          return new Promise((resolve) => {
            const ws = new WebSocket('ws://localhost:9999/my-websocket');
            ws.onopen = () => resolve('opened');
            ws.onerror = () => resolve('error');
            setTimeout(() => resolve('timeout'), 3000);
          });
        }
      """)

      assert_receive {:url, url}, 5000
      assert String.ends_with?(url, "/my-websocket")
    end

    test "can send message to page", %{assets: assets, page: page} do
      Page.route_web_socket(page, "**/ws", fn ws_route ->
        Task.start(fn ->
          Process.sleep(100)
          WebSocketRoute.send(ws_route, "hello from server")
        end)
      end)

      Page.goto(page, assets.empty)

      result =
        Page.evaluate(page, """
          () => {
            return new Promise((resolve) => {
              const ws = new WebSocket('ws://localhost:9999/ws');
              ws.onmessage = (event) => resolve(event.data);
              ws.onerror = () => resolve('error');
              setTimeout(() => resolve('timeout'), 3000);
            });
          }
        """)

      assert result == "hello from server"
    end

    test "can receive message from page", %{assets: assets, page: page} do
      test_pid = self()

      Page.route_web_socket(page, "**/ws", fn ws_route ->
        WebSocketRoute.on_message(ws_route, fn message ->
          send(test_pid, {:page_message, message})
        end)
      end)

      Page.goto(page, assets.empty)

      Page.evaluate(page, """
        () => {
          return new Promise((resolve) => {
            const ws = new WebSocket('ws://localhost:9999/ws');
            ws.onopen = () => {
              ws.send('hello from page');
              resolve('sent');
            };
            ws.onerror = () => resolve('error');
            setTimeout(() => resolve('timeout'), 3000);
          });
        }
      """)

      assert_receive {:page_message, "hello from page"}, 5000
    end

    test "can mock echo server", %{assets: assets, page: page} do
      Page.route_web_socket(page, "**/echo", fn ws_route ->
        WebSocketRoute.on_message(ws_route, fn message ->
          WebSocketRoute.send(ws_route, "echo: #{message}")
        end)
      end)

      Page.goto(page, assets.empty)

      result =
        Page.evaluate(page, """
          () => {
            return new Promise((resolve) => {
              const ws = new WebSocket('ws://localhost:9999/echo');
              ws.onopen = () => ws.send('test message');
              ws.onmessage = (event) => resolve(event.data);
              ws.onerror = () => resolve('error');
              setTimeout(() => resolve('timeout'), 3000);
            });
          }
        """)

      assert result == "echo: test message"
    end

    test "supports regex patterns", %{assets: assets, page: page} do
      test_pid = self()

      Page.route_web_socket(page, ~r/.*\/ws-\d+/, fn ws_route ->
        send(test_pid, {:matched, WebSocketRoute.url(ws_route)})
      end)

      Page.goto(page, assets.empty)

      Page.evaluate(page, """
        () => {
          return new Promise((resolve) => {
            const ws = new WebSocket('ws://localhost:9999/ws-123');
            ws.onopen = () => resolve('opened');
            ws.onerror = () => resolve('error');
            setTimeout(() => resolve('timeout'), 3000);
          });
        }
      """)

      assert_receive {:matched, url}, 5000
      assert String.ends_with?(url, "/ws-123")
    end
  end

  describe "WebSocketRoute.close/2" do
    test "can close the connection", %{assets: assets, page: page} do
      Page.route_web_socket(page, "**/ws", fn ws_route ->
        # Close the connection after a brief delay to allow the socket to open
        Task.start(fn ->
          Process.sleep(200)
          WebSocketRoute.close(ws_route, %{code: 1000, reason: "done"})
        end)
      end)

      Page.goto(page, assets.empty)

      result =
        Page.evaluate(page, """
          () => {
            return new Promise((resolve) => {
              const ws = new WebSocket('ws://localhost:9999/ws');
              ws.onopen = () => console.log('opened');
              ws.onclose = (event) => resolve({code: event.code, reason: event.reason, wasClean: event.wasClean});
              ws.onerror = (e) => resolve({error: true, message: e.message || 'unknown'});
              setTimeout(() => resolve({timeout: true}), 5000);
            });
          }
        """)

      # The close event should be received
      assert result[:code] == 1000
      assert result[:reason] == "done"
    end
  end

  describe "WebSocketRoute.on_close/2" do
    test "receives close event from page", %{assets: assets, page: page} do
      test_pid = self()

      Page.route_web_socket(page, "**/ws", fn ws_route ->
        WebSocketRoute.on_close(ws_route, fn code, reason ->
          send(test_pid, {:closed, code, reason})
        end)
      end)

      Page.goto(page, assets.empty)

      Page.evaluate(page, """
        () => {
          return new Promise((resolve) => {
            const ws = new WebSocket('ws://localhost:9999/ws');
            ws.onopen = () => {
              ws.close(1000, 'goodbye');
              resolve('closed');
            };
            ws.onerror = () => resolve('error');
            setTimeout(() => resolve('timeout'), 3000);
          });
        }
      """)

      assert_receive {:closed, 1000, "goodbye"}, 5000
    end
  end
end
