defmodule Playwright.ElementHandle.ContentFrameTest do
  use Playwright.TestCase, async: true

  alias Playwright.{ElementHandle, Page}

  describe "ElementHandle.content_frame/1" do
    test "returns a `Playwright.Frame`", %{assets: assets, page: page} do
      url = assets.empty
      Page.goto(page, url)

      frame = attach_frame(page, "frame1", url)
      assert frame.type == "Frame"

      handle = Page.query_selector(page, "#frame1")
      assert ElementHandle.content_frame(handle) == frame
    end
  end
end

# 1) test ElementHandle.content_frame/1 returns a `Playwright.Frame` (Playwright.ElementHandle.ContentFrameTest)
# test/integration/element_handle/content_frame_test.exs:7
# ** (exit) exited in: GenServer.call(#PID<0.574.0>, {:post, {:cmd, %Playwright.Runner.Channel.Command{guid: "handle@c68e681bfa5baa4f5c3b9bff2d96d91d", id: 188, metadata: %{}, method: "contentFrame", params: %{}}}}, 5000)
#     ** (EXIT) time out
# code: frame = attach_frame(page, "frame1", url)
# stacktrace:
#   (elixir 1.12.3) lib/gen_server.ex:1024: GenServer.call/3
#   test/integration/element_handle/content_frame_test.exs:11: (test)
