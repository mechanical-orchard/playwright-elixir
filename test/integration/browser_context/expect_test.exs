defmodule Playwright.BrowserContext.ExpectTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, Page}

  describe "BrowserContext expect_*" do
    @tag exclude: [:page]
    test ".expect_page/3", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      event_info =
        BrowserContext.expect_page(context, fn ->
          Page.evaluate(page, "url => window.open(url)", assets.empty)
        end)

      assert event_info.params.url == assets.empty
    end
  end
end
