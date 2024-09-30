defmodule Playwright.BrowserTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, Page, Response}

  describe "Browser.close/1" do
    @tag exclude: [:page]
    test "is callable twice", %{transport: transport} do
      {_session, inline_browser} = setup_browser(transport)
      assert :ok = Browser.close(inline_browser)
      assert :ok = Browser.close(inline_browser)
    end
  end

  describe "Browser.new_context/1" do
    @tag exclude: [:page]
    test "creates and binds a new context", %{browser: browser} do
      assert Browser.contexts(browser) == []

      Browser.new_context(browser)
      assert [%BrowserContext{} = context] = Browser.contexts(browser)
      assert context.browser == browser

      BrowserContext.close(context)
      assert Browser.contexts(browser) == []
    end

    @tag exclude: [:page]
    test "succeeds, when configured to use a proxy", %{assets: assets, browser: browser} do
      context =
        Browser.new_context(browser, %{
          proxy: %{server: assets.prefix}
        })

      page = BrowserContext.new_page(context)
      response = Page.goto(page, "http://non-existent.com/assets/dom.html")

      assert Response.ok(response)
      assert Page.text_content(page, "#inner") == "Text,\nmore text"
    end

    test "succeeds when configured with a custom `userAgent` header", %{browser: browser} do
      context = Browser.new_context(browser, %{"userAgent" => "Mozzies"})
      page = BrowserContext.new_page(context)

      assert Page.evaluate(page, "window.navigator.userAgent") == "Mozzies"

      BrowserContext.close(context)
    end

    # test_should_use_proxy_for_second_page
    # test_should_work_with_ip_port_notion
    # test_should_authenticate
    # test_should_authenticate_with_empty_password
  end

  describe "Browser.new_page/1" do
    @tag exclude: [:page]
    test "creates and binds a new context", %{browser: browser} do
      assert Browser.contexts(browser) == []

      page = Browser.new_page(browser)
      assert [%BrowserContext{} = context] = Browser.contexts(browser)
      assert context.browser == browser

      Page.close(page)
      assert Browser.contexts(browser) == []
    end

    @tag exclude: [:page]
    test "builds a new Page, incl. context", %{browser: browser} do
      assert [] = Browser.contexts(browser)

      page1 = Browser.new_page(browser)
      assert [%BrowserContext{}] = Browser.contexts(browser)

      page2 = Browser.new_page(browser)
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

    test "succeeds when configured with a custom `userAgent` header", %{browser: browser} do
      page = Browser.new_page(browser, %{"userAgent" => "Mozzies"})

      assert Page.evaluate(page, "window.navigator.userAgent") == "Mozzies"

      Page.close(page)
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
end
