defmodule Playwright.BrowserTracingTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, Page}

  describe "Browser.start_tracing/3 and Browser.stop_tracing/1" do
    test "records and returns trace data", %{browser: browser, page: page, assets: assets} do
      Browser.start_tracing(browser, page)
      Page.goto(page, assets.empty)
      trace = Browser.stop_tracing(browser)

      # Trace data should be binary with content
      assert is_binary(trace)
      assert byte_size(trace) > 0
    end

    test "works with screenshots option", %{browser: browser, page: page, assets: assets} do
      Browser.start_tracing(browser, page, %{screenshots: true})
      Page.goto(page, assets.empty)
      trace = Browser.stop_tracing(browser)

      assert is_binary(trace)
      assert byte_size(trace) > 0
    end

    test "works without page parameter", %{browser: browser, page: page, assets: assets} do
      Browser.start_tracing(browser)
      Page.goto(page, assets.empty)
      trace = Browser.stop_tracing(browser)

      assert is_binary(trace)
      assert byte_size(trace) > 0
    end

    test "trace contains valid JSON data", %{browser: browser, page: page, assets: assets} do
      Browser.start_tracing(browser, page)
      Page.goto(page, assets.empty)
      trace = Browser.stop_tracing(browser)

      # Trace should be valid JSON
      assert {:ok, _decoded} = Jason.decode(trace)
    end
  end
end
