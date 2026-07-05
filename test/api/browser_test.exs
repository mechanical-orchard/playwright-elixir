defmodule Playwright.BrowserTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, BrowserType, CDPSession, Page}

  describe "Browser.close/1" do
    @tag exclude: [:page]
    test "is callable twice", %{transport: transport} do
      {_session, inline_browser} = setup_browser(transport)
      assert :ok = Browser.close(inline_browser)
      assert :ok = Browser.close(inline_browser)
    end
  end

  describe "Browser.new_page/1" do
    @tag exclude: [:page]
    test "builds a new Page, incl. context", %{browser: browser} do
      assert [] = Browser.contexts(browser)

      {:ok, page1} = Browser.new_page(browser)
      assert [%BrowserContext{}] = Browser.contexts(browser)

      {:ok, page2} = Browser.new_page(browser)
      assert [%BrowserContext{}, %BrowserContext{}] = Browser.contexts(browser)

      Page.close(page1)
      assert [%BrowserContext{}] = Browser.contexts(browser)

      Page.close(page2)
      assert [] = Browser.contexts(browser)
    end

    test "raises an exception upon additional call to `new_page`", %{page: page} do
      assert_raise RuntimeError, "Please use Playwright.Browser.new_context/1", fn ->
        page
        |> Playwright.Page.context()
        |> Playwright.BrowserContext.new_page()
      end
    end
  end

  describe "Browser.version/1" do
    test "returns the expected version", %{browser: browser} do
      case browser.name do
        "chromium" ->
          assert %{major: major, minor: _, patch: _} = Version.parse!(browser.version)
          assert major >= 90

        _name ->
          assert %{major: _, minor: _} = Version.parse!(browser.version)
      end
    end
  end

  describe "Browser.is_connected/1" do
    test "returns true when browser is connected", %{browser: browser} do
      assert Browser.is_connected(browser) == true
    end

    @tag exclude: [:page]
    test "returns false after browser is closed", %{transport: transport} do
      {_session, inline_browser} = setup_browser(transport)
      assert Browser.is_connected(inline_browser) == true
      Browser.close(inline_browser)
      assert Browser.is_connected(inline_browser) == false
    end
  end

  describe "Browser.browser_type/1" do
    test "returns the BrowserType that launched the browser", %{browser: browser} do
      browser_type = Browser.browser_type(browser)
      assert %BrowserType{} = browser_type
    end
  end

  describe "Browser.new_browser_cdp_session/1" do
    test "creates a CDP session at browser level", %{browser: browser} do
      session = Browser.new_browser_cdp_session(browser)
      assert %CDPSession{} = session
      CDPSession.detach(session)
    end
  end
end
