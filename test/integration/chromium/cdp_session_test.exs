defmodule Playwright.Chromium.CDPSessionTest do
  use Playwright.TestCase
  alias Playwright.{Browser, BrowserContext, CDPSession, Page}

  describe "BrowserContext.new_cdp_session/1" do
    test "a page-attached CDP session", %{page: page} do
      context = Page.context(page)
      assert {:ok, %CDPSession{}} = BrowserContext.new_cdp_session(context, page)
    end

    test "a frame-attached CDP session", %{page: page} do
      context = Page.context(page)
      frame = Page.main_frame(page)
      assert {:ok, %CDPSession{}} = BrowserContext.new_cdp_session(context, frame)
    end
  end

  describe "CDPSession.send/2" do
    test "using `Runtime` methods", %{page: page} do
      context = Page.context(page)
      {:ok, session} = BrowserContext.new_cdp_session(context, page)

      CDPSession.send(session, "Runtime.enable")

      {:ok, result} =
        CDPSession.send(session, "Runtime.evaluate", %{
          expression: "window.foo = 'bar'; 'expression result'"
        })

      assert result == %{result: %{type: "string", value: "expression result"}}
      assert "bar" == Page.evaluate!(page, "() => window.foo")
    end
  end

  describe "CDPSession.on/3" do
    test "handling Runtime console events`", %{page: page} do
      pid = self()
      context = Page.context(page)

      {:ok, session} = BrowserContext.new_cdp_session(context, page)

      CDPSession.send(session, "Runtime.enable")

      CDPSession.on(session, "Runtime.consoleAPICalled", fn event ->
        send(pid, {:args, event.params.args})
      end)

      CDPSession.send(session, "Runtime.evaluate", %{
        expression: "console.log('log message');"
      })

      assert_received({:args, [%{type: "string", value: "log message"}]})
    end

    test "handling Network events", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty
      context = Page.context(page)

      {:ok, session} = BrowserContext.new_cdp_session(context, page)

      CDPSession.send(session, "Network.enable")

      CDPSession.on(session, "Network.requestWillBeSent", fn event ->
        send(pid, {:request_url, event.params.documentURL})
      end)

      Page.goto(page, url)
      assert_received({:request_url, ^url})
    end
  end

  describe "CDPSession.detach/1" do
    test "detaches the sesssion", %{page: page} do
      context = Page.context(page)
      {:ok, session} = BrowserContext.new_cdp_session(context, page)

      CDPSession.send(session, "Runtime.enable")

      {:ok, %{result: result}} =
        CDPSession.send(session, "Runtime.evaluate", %{
          expression: "3 + 1"
        })

      assert result.value == 4

      CDPSession.detach(session)

      {:error, %{message: message}} =
        CDPSession.send(session, "Runtime.evaluate", %{
          expression: "3 + 1"
        })

      assert message == "Target page, context or browser has been closed"
    end

    @tag exclude: [:page]
    test "does not break Page.close/2", %{browser: browser} do
      context = Browser.new_context!(browser)
      page = BrowserContext.new_page!(context)

      {:ok, session} = BrowserContext.new_cdp_session(context, page)

      CDPSession.detach(session)
      Page.close(page)
      BrowserContext.close(context)
    end
  end

  describe "CDPSession lifecycle" do
    @tag without: [:page]
    test "detaches on Page.close/2", %{browser: browser} do
      context = Browser.new_context!(browser)
      page = BrowserContext.new_page!(context)
      {:ok, session} = BrowserContext.new_cdp_session(context, page)

      Page.close(page)

      {:error, %{message: message}} = CDPSession.detach(session)
      assert message == "Target page, context or browser has been closed"
    end
  end
end
