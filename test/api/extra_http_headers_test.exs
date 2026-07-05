defmodule Playwright.ExtraHTTPHeadersTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page}

  describe "Page.set_extra_http_headers/2" do
    test "adds headers to requests", %{assets: assets, page: page} do
      Page.set_extra_http_headers(page, %{"X-Custom-Header" => "test-value"})

      response = Page.goto(page, assets.empty)
      assert response
    end

    test "accepts multiple headers", %{assets: assets, page: page} do
      Page.set_extra_http_headers(page, %{
        "X-Header-One" => "value1",
        "X-Header-Two" => "value2",
        "Authorization" => "Bearer token123"
      })

      response = Page.goto(page, assets.empty)
      assert response
    end

    test "converts atom keys to strings", %{assets: assets, page: page} do
      Page.set_extra_http_headers(page, %{authorization: "Bearer token"})

      response = Page.goto(page, assets.empty)
      assert response
    end
  end

  describe "BrowserContext.set_extra_http_headers/2" do
    test "adds headers to all context requests", %{browser: browser, assets: assets} do
      context = Playwright.Browser.new_context(browser)
      BrowserContext.set_extra_http_headers(context, %{"Authorization" => "Bearer token123"})

      page = BrowserContext.new_page(context)
      response = Page.goto(page, assets.empty)
      assert response

      BrowserContext.close(context)
    end

    test "headers apply to all pages in context", %{browser: browser, assets: assets} do
      context = Playwright.Browser.new_context(browser)
      BrowserContext.set_extra_http_headers(context, %{"X-Context-Header" => "shared"})

      page1 = BrowserContext.new_page(context)
      page2 = BrowserContext.new_page(context)

      response1 = Page.goto(page1, assets.empty)
      response2 = Page.goto(page2, assets.empty)

      assert response1
      assert response2

      BrowserContext.close(context)
    end
  end
end
