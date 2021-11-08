# src: browsercontext-basic.spec.ts
defmodule Test.Features.BrowserContext.BasicTest do
  use Playwright.TestCase, async: true

  # describe "contexts/1" do
  #   test "returns a list of open browser contexts" do
  #   end
  # end

  describe ".new_context/1" do
    @tag exclude: [:page]
    test "creates a new context, bound to the browser", %{browser: browser} do
      assert Playwright.Browser.contexts(browser) == []

      context = Playwright.Browser.new_context(browser)
      assert Playwright.Browser.contexts(browser) == [context]
      assert context.browser == browser

      Playwright.BrowserContext.close(context)
      assert Playwright.Browser.contexts(browser) == []
    end
  end
end
