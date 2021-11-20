defmodule Playwright.BrowserContextTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, Page}

  describe "BrowserContext.new_context/1" do
    @tag exclude: [:page]
    test "creates and binds a new context", %{browser: browser} do
      assert Browser.contexts(browser) == []

      {:ok, context} = Browser.new_context(browser)
      assert Browser.contexts(browser) == [context]
      assert context.browser == browser

      BrowserContext.close(context)
      assert Browser.contexts(browser) == []
    end
  end

  describe "BrowserContext cookies" do
    test ".cookies/1", %{assets: assets, page: page} do
      page |> Page.goto(assets.extras <> "/cookiesapi.html")
      cookies = BrowserContext.cookies(page.owned_context)

      assert cookies ==
               {:ok,
                [
                  %{
                    name: "testcookie",
                    value: "crunchcrunch",
                    domain: "localhost",
                    expires: -1,
                    httpOnly: false,
                    path: "/",
                    sameSite: "Lax",
                    secure: false
                  }
                ]}
    end

    test ".add_cookies/2", %{assets: assets, page: page} do
      cookies = BrowserContext.cookies(page.owned_context)
      assert cookies == {:ok, []}

      BrowserContext.add_cookies(page.owned_context, [
        %{
          name: "testcookie",
          value: "crunchcrunch",
          domain: "localhost",
          expires: -1,
          httpOnly: false,
          path: "/",
          sameSite: "Lax",
          secure: false
        }
      ])

      Page.goto(page, assets.prefix <> "/empty.html")
      cookies = BrowserContext.cookies(page.owned_context)

      assert cookies ==
               {:ok,
                [
                  %{
                    name: "testcookie",
                    value: "crunchcrunch",
                    domain: "localhost",
                    expires: -1,
                    httpOnly: false,
                    path: "/",
                    sameSite: "Lax",
                    secure: false
                  }
                ]}
    end
  end
end
