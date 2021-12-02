defmodule Playwright.BrowserContextTest do
  use Playwright.TestCase
  alias Playwright.{Browser, BrowserContext}

  describe "BrowserContext.new_context/1" do
    @tag exclude: [:page]
    test "creates and binds a new context", %{browser: browser} do
      assert Browser.contexts(browser) == {:ok, []}

      {:ok, context} = Browser.new_context(browser)
      assert Browser.contexts(browser) == {:ok, [context]}
      assert context.browser == browser

      BrowserContext.close(context)
      assert Browser.contexts(browser) == {:ok, []}
    end
  end
end
