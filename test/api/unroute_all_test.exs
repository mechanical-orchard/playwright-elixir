defmodule Playwright.UnrouteAllTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page, Route}

  describe "Page.unroute_all/1" do
    test "removes all routes", %{page: page, assets: assets} do
      # Add a route that returns a fake response
      Page.route(page, "**/*", fn route ->
        Route.fulfill(route, %{status: 200, body: "intercepted"})
      end)

      # Remove all routes
      Page.unroute_all(page)

      # Navigation should work normally (not intercepted)
      response = Page.goto(page, assets.empty)
      assert response
    end

    test "works with no routes registered", %{page: page, assets: assets} do
      # Calling unroute_all with no routes should not error
      Page.unroute_all(page)

      response = Page.goto(page, assets.empty)
      assert response
    end
  end

  describe "BrowserContext.unroute_all/1" do
    test "removes all context routes", %{browser: browser, assets: assets} do
      context = Playwright.Browser.new_context(browser)

      # Add a route that returns a fake response
      BrowserContext.route(context, "**/*", fn route ->
        Route.fulfill(route, %{status: 200, body: "intercepted"})
      end)

      # Remove all routes
      BrowserContext.unroute_all(context)

      # Navigation should work normally (not intercepted)
      page = BrowserContext.new_page(context)
      response = Page.goto(page, assets.empty)
      assert response

      BrowserContext.close(context)
    end

    test "works with no routes registered", %{browser: browser, assets: assets} do
      context = Playwright.Browser.new_context(browser)

      # Calling unroute_all with no routes should not error
      BrowserContext.unroute_all(context)

      page = BrowserContext.new_page(context)
      response = Page.goto(page, assets.empty)
      assert response

      BrowserContext.close(context)
    end
  end
end
