defmodule Playwright.NavigationTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Page, Response}
  alias Playwright.SDK.Channel.Error

  describe "Page.goto/2" do
    test "works (and updates the page's URL)", %{assets: assets, page: page} do
      assert Page.url(page) == assets.blank

      Page.goto(page, assets.empty)
      assert Page.url(page) == assets.empty
    end

    test "works with anchor navigation", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      assert Page.url(page) == assets.empty

      Page.goto(page, assets.empty <> "#foo")
      assert Page.url(page) == assets.empty <> "#foo"

      Page.goto(page, assets.empty <> "#bar")
      assert Page.url(page) == assets.empty <> "#bar"
    end

    test "navigates to about:blank", %{assets: assets, page: page} do
      response = Page.goto(page, assets.blank)
      refute response
    end

    test "returns response when page changes its URL after load", %{assets: assets, page: page} do
      response = Page.goto(page, assets.prefix <> "/historyapi.html")
      assert response.status == 200
    end

    # !!! works w/out implementation
    test "navigates to empty page with domcontentloaded", %{assets: assets, page: page} do
      response = Page.goto(page, assets.empty, %{wait_until: "domcontentloaded"})
      assert response.status == 200
    end

    test "works when page calls history API in beforeunload", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)

      Page.evaluate(page, """
      () => {
        window.addEventListener('beforeunload', () => history.replaceState(null, 'initial', window.location.href), false)
      }
      """)

      response = Page.goto(page, assets.prefix <> "/grid.html")
      assert response.status == 200
    end

    test "fails when navigating to bad URL", %{page: page} do
      error = %Error{
        message: "Protocol error (Page.navigate): Cannot navigate to invalid URL"
      }

      assert Page.goto(page, "asdfasdf") == {:error, error}
    end

    test "works when navigating to valid URL", %{assets: assets, page: page} do
      response = Page.goto(page, assets.empty)
      assert Response.ok(response)

      response = Page.goto(page, assets.empty)
      assert Response.ok(response)
    end
  end
end
