defmodule Playwright.BrowserType.ConnectCDPTest do
  @remote_debug_port "9222"

  use Playwright.TestCase, async: true, args: ["--remote-debugging-port=#{@remote_debug_port}"]

  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.BrowserType
  alias Playwright.Page

  @tag :skip
  test "can only connect to CDP session if using chromium client" do
    # For some reason this still launches a chromium browser... I could not
    # figure out why.

    browser = Playwright.launch(:firefox)

    expected_message = "Attempted to use Playwright.BrowserType.connect_over_cdp/3 with incompatible browser client"

    assert_raise RuntimeError, expected_message, fn ->
      BrowserType.connect_over_cdp(
        browser,
        "http://localhost:#{@remote_debug_port}/"
      )
    end
  end

  test "can connect to an existing CDP session via http endpoint", %{browser: browser} do
    cdp_browser =
      BrowserType.connect_over_cdp(
        browser,
        "http://localhost:#{@remote_debug_port}/"
      )

    assert length(Browser.contexts(cdp_browser)) == 1

    Browser.close(cdp_browser)
  end

  @tag exclude: [:page]
  test "can connect to an existing CDP session twice", %{browser: browser, assets: assets} do
    cdp_browser1 =
      BrowserType.connect_over_cdp(
        browser,
        "http://localhost:#{@remote_debug_port}/"
      )

    cdp_browser2 =
      BrowserType.connect_over_cdp(
        browser,
        "http://localhost:#{@remote_debug_port}/"
      )

    cdp_browser3 =
      BrowserType.connect_over_cdp(
        browser,
        "http://localhost:#{@remote_debug_port}/"
      )

    assert length(contexts(cdp_browser1)) == 1

    page1 =
      contexts(cdp_browser1)
      |> List.first()
      |> BrowserContext.new_page()

    Page.goto(page1, assets.empty)

    assert length(contexts(cdp_browser2)) == 1

    page2 =
      contexts(cdp_browser2)
      |> List.first()
      |> BrowserContext.new_page()

    Page.goto(page2, assets.empty)

    assert contexts(cdp_browser1)
           |> List.first()
           |> pages()
           |> length() == 2

    assert contexts(cdp_browser2)
           |> List.first()
           |> pages()
           |> length() == 2

    # NOTE: no `Page` was explicitly created off of `cdp_browser3`, but its context includes
    # those created by the other sessions. See docs in `BrowserType.connect_over_cdp/3`
    assert contexts(cdp_browser3)
           |> List.first()
           |> pages()
           |> length() == 2

    Browser.close(cdp_browser1)
    Browser.close(cdp_browser2)
    Browser.close(cdp_browser3)
  end

  test "can connect over a websocket endpoint", %{browser: browser} do
    ws_endpoint = ws_endpoint_for_url("http://localhost:#{@remote_debug_port}/json/version")

    cdp_browser1 = BrowserType.connect_over_cdp(browser, ws_endpoint)
    assert contexts(cdp_browser1) |> length() == 1
    Browser.close(cdp_browser1)

    cdp_browser2 = BrowserType.connect_over_cdp(browser, ws_endpoint)
    assert contexts(cdp_browser2) |> length() == 1
    Browser.close(cdp_browser2)
  end

  defp ws_endpoint_for_url(url) do
    {:ok, %{body: body}} = HTTPoison.get(url)

    Jason.decode!(body)
    |> Map.get("webSocketDebuggerUrl")
  end

  defp contexts(browser), do: Browser.contexts(browser)
  defp pages(context), do: BrowserContext.pages(context)
end
