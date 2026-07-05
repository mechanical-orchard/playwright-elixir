defmodule Playwright.TracingTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, Page, Tracing}

  describe "Tracing" do
    test "start and stop without path", %{browser: browser} do
      context = Browser.new_context(browser)
      tracing = BrowserContext.tracing(context)

      assert :ok = Tracing.start(tracing, %{screenshots: true})
      assert :ok = Tracing.stop(tracing)

      BrowserContext.close(context)
    end

    test "start and stop with path", %{page: page} do
      context = Page.context(page)
      tracing = BrowserContext.tracing(context)
      path = Path.join(System.tmp_dir!(), "trace-#{:rand.uniform(10000)}.zip")

      try do
        Tracing.start(tracing, %{screenshots: true, snapshots: true})
        Page.set_content(page, "<h1>Hello Tracing</h1>")
        Tracing.stop(tracing, %{path: path})

        assert File.exists?(path)
      after
        File.rm(path)
      end
    end

    test "start with name option", %{browser: browser} do
      context = Browser.new_context(browser)
      tracing = BrowserContext.tracing(context)

      assert :ok = Tracing.start(tracing, %{name: "my-trace", screenshots: true})
      assert :ok = Tracing.stop(tracing)

      BrowserContext.close(context)
    end

    test "start_chunk and stop_chunk", %{browser: browser} do
      context = Browser.new_context(browser)
      tracing = BrowserContext.tracing(context)
      path = Path.join(System.tmp_dir!(), "trace-chunk-#{:rand.uniform(10000)}.zip")

      try do
        Tracing.start(tracing, %{screenshots: true})
        Tracing.stop_chunk(tracing, %{path: path})
        Tracing.stop(tracing)

        assert File.exists?(path)
      after
        File.rm(path)
        BrowserContext.close(context)
      end
    end

    test "group and group_end", %{browser: browser} do
      context = Browser.new_context(browser)
      tracing = BrowserContext.tracing(context)

      Tracing.start(tracing, %{screenshots: true})
      assert :ok = Tracing.group(tracing, "My Group")
      assert :ok = Tracing.group_end(tracing)
      Tracing.stop(tracing)

      BrowserContext.close(context)
    end

    test "group with location option", %{browser: browser} do
      context = Browser.new_context(browser)
      tracing = BrowserContext.tracing(context)

      Tracing.start(tracing, %{screenshots: true})

      location = %{file: "test.exs", line: 10, column: 1}
      assert :ok = Tracing.group(tracing, "Test Group", %{location: location})
      assert :ok = Tracing.group_end(tracing)

      Tracing.stop(tracing)
      BrowserContext.close(context)
    end

    test "multiple chunks", %{browser: browser} do
      context = Browser.new_context(browser)
      tracing = BrowserContext.tracing(context)
      path1 = Path.join(System.tmp_dir!(), "trace-chunk1-#{:rand.uniform(10000)}.zip")
      path2 = Path.join(System.tmp_dir!(), "trace-chunk2-#{:rand.uniform(10000)}.zip")

      try do
        Tracing.start(tracing, %{screenshots: true})
        Tracing.stop_chunk(tracing, %{path: path1})

        Tracing.start_chunk(tracing, %{title: "Chunk 2"})
        Tracing.stop_chunk(tracing, %{path: path2})

        Tracing.stop(tracing)

        assert File.exists?(path1)
        assert File.exists?(path2)
      after
        File.rm(path1)
        File.rm(path2)
        BrowserContext.close(context)
      end
    end
  end
end
