defmodule Playwright.WIPTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Page}

  require Logger

  describe "WIP" do
    @tag exclude: [:page]
    test "BrowserType.launch", %{browser: browser} do
      assert browser
    end

    @tag :skip
    test "...A", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "requestFinished", fn %{params: %{request: request}} ->
        send(pid, {:finished, request.url})
      end)

      event_info = Page.expect_event(page, "requestFinished", fn ->
        Page.goto(page, url)
      end)

      assert event_info.target == Page.context(page)
      assert event_info.params.response.url == url
      assert_next_receive({:finished, ^url})
    end
  end
end
