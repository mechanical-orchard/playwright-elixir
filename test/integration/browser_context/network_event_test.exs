defmodule Test.BrowserContext.NetworkEventTest do
  use Playwright.TestCase, async: true

  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.Page

  describe "BrowserContext network events" do
    # flaky in CI
    @tag :skip
    @tag without: [:page]
    test "on: request", %{assets: assets, browser: browser} do
      this = self()

      context = Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      BrowserContext.on(context, "request", fn _, %{params: %{request: request}} ->
        send(this, request.url)
      end)

      Page.goto(page, assets.prefix <> "/empty.html")
      Page.set_content(page, "<a target=_blank rel=noopener href='/one-style.html'>yo</a>")
      Page.click(page, "a")

      # BrowserContext.wait_for_event(context, "page")
      # Page.wait_for_load_state(page)

      recv_1 = assets.empty
      recv_2 = assets.prefix <> "/one-style.html"
      # recv_3 = assets.prefix <> "/one-style.css"

      assert_received(^recv_1)
      assert_received(^recv_2)
      # assert_received(^recv_3)
    end
  end
end
