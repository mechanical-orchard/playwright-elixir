defmodule Playwright.BrowserTest do
  use Playwright.TestCase, async: true
  alias Playwright.API.Error
  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.BrowserType
  alias Playwright.CDPSession
  alias Playwright.Page
  alias Playwright.Response

  describe "Browser.browser_type/1" do
    test "returns the 'parent' `BrowserType`", %{browser: browser} do
      assert %BrowserType{} = Browser.browser_type(browser)
    end
  end

  describe "Browser.close/2" do
    @tag exclude: [:page]
    test "on success, returns `:ok`", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      assert :ok = Browser.close(browser)
    end

    @tag exclude: [:page]
    test "is callable twice", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      assert :ok = Browser.close(browser)
      assert :ok = Browser.close(browser)
    end

    @tag exclude: [:page]
    test "accepts a `:reason` option", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      assert :ok = Browser.close(browser, %{reason: "All done."})
    end
  end

  describe "Browser.contexts/1" do
    @tag exclude: [:page]
    test "for a newly created `Browser`, returns an empty list", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      assert Browser.contexts(browser) == []
    end

    @tag exclude: [:page]
    test "when related `BrowserContext` instances are created, lists those", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      context1 = Browser.new_context(browser)
      context2 = Browser.new_context(browser)

      desired = [context1, context2] |> Enum.sort()
      assert ^desired = Browser.contexts(browser) |> Enum.sort()

      BrowserContext.close(context1)
      BrowserContext.close(context2)
    end

    @tag exclude: [:page]
    test "when related `BrowserContext` instances are closed, excludes those", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      context = Browser.new_context(browser)
      assert [^context] = Browser.contexts(browser)

      BrowserContext.close(context)
      assert Browser.contexts(browser) == []
    end
  end

  describe "Browser.new_browser_cdp_session/1" do
    test "on success, returns a new `CDPSession`", %{browser: browser} do
      assert %CDPSession{} = Browser.new_browser_cdp_session(browser)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      browser = %{browser | guid: "bogus"}
      assert {:error, %Error{type: "TargetClosedError"}} = Browser.new_browser_cdp_session(browser)
    end
  end

  describe "Browser.new_browser_cdp_session!/1" do
    test "on success, returns a new `CDPSession`", %{browser: browser} do
      assert %CDPSession{} = Browser.new_browser_cdp_session!(browser)
    end

    test "on failure, raises", %{browser: browser} do
      assert_raise RuntimeError, fn ->
        browser = %{browser | guid: "bogus"}
        Browser.new_browser_cdp_session!(browser)
      end
    end
  end

  describe "Browser.new_context/1" do
    test "on success, returns a new `BrowserContext`", %{browser: browser} do
      assert %BrowserContext{} = context = Browser.new_context(browser)
      BrowserContext.close(context)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      browser = %{browser | guid: "bogus"}
      assert {:error, %Error{type: "TargetClosedError"}} = Browser.new_context(browser)
    end

    @tag exclude: [:page]
    test "creates and binds a new context", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
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

      Page.close(page)
    end

    @tag exclude: [:page]
    test "succeeds when configured with a custom `userAgent` header", %{browser: browser} do
      context = Browser.new_context(browser, %{"userAgent" => "Mozzies"})
      page = BrowserContext.new_page(context)

      assert Page.evaluate(page, "window.navigator.userAgent") == "Mozzies"

      BrowserContext.close(context)
      Page.close(page)
    end

    # test_should_use_proxy_for_second_page
    # test_should_work_with_ip_port_notion
    # test_should_authenticate
    # test_should_authenticate_with_empty_password
  end

  describe "Browser.new_context!/1" do
    test "on success, returns a new `BrowserContext`", %{browser: browser} do
      assert %BrowserContext{} = Browser.new_context!(browser)
    end

    test "on failure, raises", %{browser: browser} do
      assert_raise RuntimeError, fn ->
        browser = %{browser | guid: "bogus"}
        Browser.new_context!(browser)
      end
    end
  end

  describe "Browser.new_context!/2" do
    test "on success, returns a new `BrowserContext`", %{browser: browser} do
      assert %BrowserContext{} = Browser.new_context!(browser, %{base_url: "https://example.com"})
    end

    test "on failure, raises", %{browser: browser} do
      assert_raise RuntimeError, fn ->
        browser = %{browser | guid: "bogus"}
        Browser.new_context!(browser, %{base_url: "https://example.com"})
      end
    end
  end

  describe "Browser.new_page/1" do
    @tag exclude: [:page]
    test "creates and binds a new context", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      assert Browser.contexts(browser) == []

      page = Browser.new_page(browser)
      assert [%BrowserContext{} = context] = Browser.contexts(browser)
      assert context.browser == browser

      Page.close(page)
      assert Browser.contexts(browser) == []
    end

    @tag exclude: [:page]
    test "builds a new Page, incl. context", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
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

  # skip: the `:disconnected` event is meant to be emitted from the client-side,
  # upon `Browser.close/1`; we don't yet have a good mechanism for that.
  # describe "Browser.on/3" do
  #   @tag :skip
  #   test "on success, returns the 'subject' `Browser`", %{transport: transport} do
  #     {_session, browser} = setup_browser(transport)
  #     assert %Browser{} = Browser.on(browser, :disconnected, fn -> nil end)
  #   end

  #   @tag :skip
  #   test "on `:disconnected`, ...", %{transport: transport} do
  #     {_session, browser} = setup_browser(transport)

  #     Browser.on(browser, :disconnected, fn data ->
  #       IO.inspect(data, label: "on(:disconnected) data ->")
  #     end)

  #     Browser.close(browser)
  #   end
  # end

  describe "Browser.start_tracing/3" do
    test "on success, returns the 'subject' `Browser`", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      assert %Browser{} = Browser.start_tracing(browser)
      Browser.stop_tracing(browser)
    end

    test "on failure, returns `{:error, error}`", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      browser = %{browser | guid: "bogus"}
      assert {:error, %Error{type: "TargetClosedError"}} = Browser.start_tracing(browser)
    end
  end

  describe "Browser.start_tracing!/3" do
    test "on success, returns the 'subject' `Browser`", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      assert %Browser{} = Browser.start_tracing!(browser)
      Browser.stop_tracing(browser)
    end

    test "on failure, raises", %{transport: transport} do
      {_session, browser} = setup_browser(transport)

      assert_raise RuntimeError, fn ->
        browser = %{browser | guid: "bogus"}
        Browser.start_tracing!(browser)
      end
    end
  end

  describe "Browser.stop_tracing/1" do
    test "on success, returns the resultant `Artifact`", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      Browser.start_tracing(browser)
      assert %Playwright.Artifact{} = Browser.stop_tracing(browser)
    end

    test "on failure, returns `{:error, error}`", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      Browser.start_tracing(browser)
      browser = %{browser | guid: "bogus"}
      assert {:error, %Error{type: "TargetClosedError"}} = Browser.start_tracing(browser)
    end
  end

  describe "Browser.stop_tracing!/3" do
    test "on success, returns the resultant `Artifact`", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      Browser.start_tracing(browser)
      assert %Playwright.Artifact{} = Browser.stop_tracing!(browser)
    end

    test "on failure, raises", %{transport: transport} do
      {_session, browser} = setup_browser(transport)
      Browser.start_tracing(browser)

      assert_raise RuntimeError, fn ->
        browser = %{browser | guid: "bogus"}
        Browser.stop_tracing!(browser)
      end
    end
  end

  describe "Browser.version/1" do
    test "returns the expected version", %{browser: browser} do
      case browser.name do
        "chromium" ->
          assert %{major: major, minor: _, patch: _} = Version.parse!(Browser.version(browser))
          assert major >= 90

        _name ->
          assert %{major: _, minor: _} = Version.parse!(Browser.version(browser))
      end
    end
  end
end
