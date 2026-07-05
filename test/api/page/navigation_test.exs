defmodule Playwright.Page.NavigationTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page.go_back/2" do
    test "navigates back in history", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      Page.goto(page, assets.dom)

      assert String.ends_with?(Page.url(page), "/dom.html")

      Page.go_back(page)
      assert String.ends_with?(Page.url(page), "/empty.html")
    end

    test "returns nil when no history", %{page: page} do
      assert Page.go_back(page) == nil
    end
  end

  describe "Page.go_forward/2" do
    test "navigates forward in history", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      Page.goto(page, assets.dom)
      Page.go_back(page)

      assert String.ends_with?(Page.url(page), "/empty.html")

      Page.go_forward(page)
      assert String.ends_with?(Page.url(page), "/dom.html")
    end

    test "returns nil when no forward history", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      assert Page.go_forward(page) == nil
    end
  end

  describe "Page.wait_for_url/3" do
    test "resolves immediately if URL already matches", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      result = Page.wait_for_url(page, "**/empty.html")
      assert %Page{} = result
    end

    test "matches with regex pattern", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      result = Page.wait_for_url(page, ~r/empty\.html$/)
      assert %Page{} = result
    end

    test "matches with function predicate", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      result = Page.wait_for_url(page, fn url -> String.contains?(url, "empty") end)
      assert %Page{} = result
    end

    test "times out when URL does not match", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      result = Page.wait_for_url(page, "**/nonexistent.html", %{timeout: 100})
      assert {:error, %{message: "Timeout waiting for URL to match pattern"}} = result
    end
  end
end
