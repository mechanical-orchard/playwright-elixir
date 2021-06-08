defmodule Test.Features.BrowserTest do
  use ExUnit.Case
  use PlaywrightTest.Case, transport: :driver

  describe "new_page/1" do
    test "creates a new Page", %{browser: browser} do
      page = Browser.new_page(browser)
      assert page.type == "Page"
      Page.close(page)
    end

    test "creates a new 'owned' Context for each new Page, which will be cleaned up when the Page is closed", %{
      browser: browser
    } do
      page1 = Browser.new_page(browser)
      assert length(Browser.contexts(browser)) == 1

      page2 = Browser.new_page(browser)
      assert length(Browser.contexts(browser)) == 2

      Page.close(page1)
      assert length(Browser.contexts(browser)) == 1

      Page.close(page2)
      assert Browser.contexts(browser) == []
    end
  end
end
