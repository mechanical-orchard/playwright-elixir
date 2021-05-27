defmodule Playwright.BrowserTest do
  use ExUnit.Case
  use PlaywrightTest.Case

  describe "new_page/1" do
    test "creates a new Page, within a new Context", %{browser: browser} do
      page1 = Browser.new_page(browser)
      assert page1.type == "Page"
    end

    @tag :skip
    test "creates a new Context for each new Page", %{browser: browser} do
      page1 = Browser.new_page(browser)
      assert length(Browser.contexts(browser)) == 1

      page2 = Browser.new_page(browser)
      assert length(Browser.contexts(browser)) == 2

      Page.close(page1)
      assert length(Browser.contexts(browser)) == 1

      Page.close(page2)
      assert length(Browser.contexts(browser)) == 0
    end
  end
end
