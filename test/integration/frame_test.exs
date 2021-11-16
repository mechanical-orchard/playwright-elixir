defmodule Playwright.FrameTest do
  use Playwright.TestCase, async: true

  alias Playwright.{Frame, Page}

  describe "Playwright.Frame" do
    test "on 'navigated'", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Frame.on(Page.frame(page), "navigated", fn %{params: %{newDocument: document}} ->
        assert document.request.url == url
        send(pid, document.request.url)
      end)

      Page.goto(page, url)
      assert_received(^url)
    end
  end
end
