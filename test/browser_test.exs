defmodule Playwright.BrowserTest do
  use ExUnit.Case
  use PlaywrightTest.Case

  describe "new_page/1" do
    test "creates a new Page, within a new Context", %{browser: browser} do
      page1 = Browser.new_page(browser)
      assert page1.type == "Page"
    end
  end
end
