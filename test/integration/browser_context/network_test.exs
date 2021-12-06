defmodule Playwright.BrowserContext.NetworkTest do
  use Playwright.TestCase
  alias Playwright.{Browser, BrowserContext, Page}

  describe "BrowserContext network events" do
    @tag without: [:page]
    test "on :request", %{assets: assets, browser: browser} do
      this = self()

      context = Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      BrowserContext.on(context, "request", fn %{params: %{request: request}} ->
        send(this, request.url)
      end)

      page |> Page.goto(assets.prefix <> "/empty.html")
      page |> Page.set_content("<a target=_blank rel=noopener href='/assets/one-style.html'>yo</a>")

      BrowserContext.expect_event(context, "page", fn ->
        page |> Page.click("a")
      end)

      assert %Page{} = Page.wait_for_load_state(page)

      recv_1 = assets.empty
      recv_2 = assets.prefix <> "/one-style.html"
      # recv_3 = assets.prefix <> "/one-style.css"

      assert_received(^recv_1)
      assert_received(^recv_2)
      # assert_received(^recv_3)
    end
  end
end
