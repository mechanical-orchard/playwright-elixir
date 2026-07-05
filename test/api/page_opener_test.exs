defmodule Playwright.PageOpenerTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page.opener/1" do
    test "returns nil for regular page", %{page: page} do
      assert Page.opener(page) == nil
    end

    test "returns nil for page created via new_page", %{browser: browser} do
      {:ok, page} = Playwright.Browser.new_page(browser)
      assert Page.opener(page) == nil
      Page.close(page)
    end
  end
end
