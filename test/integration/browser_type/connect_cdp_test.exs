defmodule Playwright.BrowserType.ConnectCDPTest do
  @remote_debug_port "9223"

  use Playwright.TestCase, async: true, args: ["--remote-debugging-port=#{@remote_debug_port}"]

  alias Playwright.{Browser, BrowserType, BrowserContext, Page}

  describe "BrowserType.connect_over_cdp/3" do
    test "can connect to an existing cdp session", %{browser: browser} do
      {_, cdp_browser} = BrowserType.connect_over_cdp(:chromium, "http://localhost:#{@remote_debug_port}")

      assert_browser_context_count(cdp_browser, 1)
      assert_page_count(cdp_browser, 1)
      assert browser.session != cdp_browser.session
    end

    @tag exclude: [:page]
    test "can connect to an existing CDP Session twice", %{browser: _browser, assets: assets} do
      {_, cdp_browser1} = BrowserType.connect_over_cdp(:chromium, "http://localhost:#{@remote_debug_port}")
      {_, cdp_browser2} = BrowserType.connect_over_cdp(:chromium, "http://localhost:#{@remote_debug_port}")

      assert_browser_context_count(cdp_browser1, 1)
      assert_browser_context_count(cdp_browser2, 1)

      assert_page_count(cdp_browser1, 0)
      assert_page_count(cdp_browser2, 0)

      page1 = create_new_page(cdp_browser1, assets.empty)
      assert_page_count(cdp_browser1, 1)
      assert_page_count(cdp_browser2, 1)

      page2 = create_new_page(cdp_browser2, assets.empty)
      assert_page_count(cdp_browser1, 2)
      assert_page_count(cdp_browser2, 2)

      close_page(page1)
      close_page(page2)
    end

    test "can connect over a websocket endpoint", %{browser: _browser} do
      ws_endpoint = ws_endpoint_for_url("http://localhost:#{@remote_debug_port}/json/version")
      {_, cdp_browser1} = BrowserType.connect_over_cdp(:chromium, ws_endpoint)

      assert_browser_context_count(cdp_browser1, 1)

      {_, cdp_browser2} = BrowserType.connect_over_cdp(:chromium, ws_endpoint)
      assert_browser_context_count(cdp_browser2, 1)
    end

    defp ws_endpoint_for_url(url) do
      url
      |> HTTPoison.get!()
      |> Map.get(:body)
      |> Jason.decode!()
      |> Map.get("webSocketDebuggerUrl")
    end

    defp create_new_page(%Browser{} = browser, url) do
      page = browser |> Browser.contexts() |> Enum.at(0) |> BrowserContext.new_page()
      page |> Page.goto(url)
      page
    end

    defp close_page(%Page{} = page) do
      page |> Page.close()
    end

    defp assert_browser_context_count(%Browser{} = browser, expected_count) do
      assert browser |> Browser.contexts() |> length() == expected_count
    end

    defp assert_page_count(%Browser{} = browser, expected_count) do
      assert browser |> Browser.contexts() |> Enum.at(0) |> BrowserContext.pages() |> length() == expected_count
    end
  end
end
