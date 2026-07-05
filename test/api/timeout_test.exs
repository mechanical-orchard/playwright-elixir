defmodule Playwright.TimeoutTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page}

  describe "Page.set_default_timeout/2" do
    test "sets default timeout for page operations", %{page: page} do
      assert :ok = Page.set_default_timeout(page, 5000)
    end

    test "accepts large timeout values", %{page: page} do
      assert :ok = Page.set_default_timeout(page, 120_000)
    end
  end

  describe "Page.set_default_navigation_timeout/2" do
    test "sets default navigation timeout", %{page: page} do
      assert :ok = Page.set_default_navigation_timeout(page, 10_000)
    end

    test "accepts zero to disable timeout", %{page: page} do
      assert :ok = Page.set_default_navigation_timeout(page, 0)
    end
  end

  describe "BrowserContext.set_default_timeout/2" do
    test "sets default timeout on context", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      assert :ok = BrowserContext.set_default_timeout(context, 5000)
      BrowserContext.close(context)
    end
  end

  describe "BrowserContext.set_default_navigation_timeout/2" do
    test "sets default navigation timeout on context", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      assert :ok = BrowserContext.set_default_navigation_timeout(context, 10_000)
      BrowserContext.close(context)
    end
  end
end
