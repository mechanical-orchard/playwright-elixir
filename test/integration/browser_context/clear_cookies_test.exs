defmodule Playwright.BrowserContext.ClearCookiesTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page}

  describe "BrowserContext.clear_cookies/1" do
    test "clears cookies for the context", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.add_cookies(context, [%{url: assets.empty, name: "cookie1", value: "one"}])
      assert Page.evaluate(page, "document.cookie") == "cookie1=one"

      BrowserContext.clear_cookies(context)
      assert BrowserContext.cookies(context) == []

      Page.reload(page)
      assert Page.evaluate(page, "document.cookie") == ""
    end

    # test_should_isolate_cookies_when_clearing
  end
end
