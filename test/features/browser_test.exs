defmodule Test.Features.BrowserTest do
  use Playwright.TestCase

  describe "new_page/1" do
    test "creates a new Page", %{browser: browser} do
      page = Playwright.Browser.new_page(browser)
      assert page.type == "Page"
      Playwright.Page.close(page)
    end

    test "creates a new 'owned' Context for each new Page, which will be cleaned up when the Page is closed", %{
      browser: browser
    } do
      page1 = Playwright.Browser.new_page(browser)
      assert length(Playwright.Browser.contexts(browser)) == 1

      page2 = Playwright.Browser.new_page(browser)
      assert length(Playwright.Browser.contexts(browser)) == 2

      Playwright.Page.close(page1)
      assert length(Playwright.Browser.contexts(browser)) == 1

      Playwright.Page.close(page2)
      assert Playwright.Browser.contexts(browser) == []
    end

    test "enforces 1-to-1 on Page and Context", %{browser: browser} do
      page = Playwright.Browser.new_page(browser)

      assert_raise RuntimeError, "Please use Playwright.Browser.new_context/1", fn ->
        page
        |> Playwright.Page.context()
        |> Playwright.BrowserContext.new_page()
      end

      Playwright.Page.close(page)
    end
  end
end
