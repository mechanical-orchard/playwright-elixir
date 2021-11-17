defmodule Playwright.WIPTest do
  use Playwright.TestCase, async: true
  require Logger

  describe "WIP" do
    test "on .query_selector_all/2", %{assets: assets, page: page} do
      # Playwright.Page.on(page, "console", fn info ->
      #   Logger.warn("console: #{inspect(info.params)}")
      # end)
      Playwright.Page.goto(page, assets.prefix <> "/dom.html")
      Playwright.Page.query_selector_all(page, "css=div")
    end

    # ---

    @tag exclude: [:page]
    test "startup readiness", %{assets: assets, browser: browser} do
      # assert Playwright.Browser.new_context(browser)
      page = Playwright.Browser.new_page(browser)
      Playwright.Page.goto(page, assets.empty)
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
