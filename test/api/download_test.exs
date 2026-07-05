defmodule Playwright.DownloadTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Download, Page}
  alias Playwright.SDK.Channel.Event

  describe "Download" do
    test "receives download event with artifact", %{assets: assets, browser: browser} do
      test_pid = self()

      # Create a new context with accept_downloads enabled
      context = Playwright.Browser.new_context(browser, %{accept_downloads: "accept"})
      page = Playwright.BrowserContext.new_page(context)

      Page.on(page, :download, fn %Event{} = event ->
        Task.start(fn ->
          download = Download.from_event(event)
          send(test_pid, {:download, download})
        end)
      end)

      Page.goto(page, assets.prefix <> "/download-blob.html")
      Page.click(page, "a")

      assert_receive({:download, download}, 10_000)
      assert %Download{} = download
      assert Download.suggested_filename(download) == "example.txt"

      Playwright.BrowserContext.close(context)
    end

    test "save_as saves download to file", %{assets: assets, browser: browser} do
      test_pid = self()
      save_path = Path.join(System.tmp_dir!(), "download_test_#{:rand.uniform(100_000)}.txt")

      context = Playwright.Browser.new_context(browser, %{accept_downloads: "accept"})
      page = Playwright.BrowserContext.new_page(context)

      Page.on(page, :download, fn %Event{} = event ->
        Task.start(fn ->
          download = Download.from_event(event)
          result = Download.save_as(download, save_path)
          send(test_pid, {:save_result, result})
        end)
      end)

      Page.goto(page, assets.prefix <> "/download-blob.html")
      Page.click(page, "a")

      assert_receive({:save_result, :ok}, 10_000)
      assert File.exists?(save_path)
      assert File.read!(save_path) == "Hello world"

      File.rm!(save_path)
      Playwright.BrowserContext.close(context)
    end

    test "path returns download path", %{assets: assets, browser: browser} do
      test_pid = self()

      context = Playwright.Browser.new_context(browser, %{accept_downloads: "accept"})
      page = Playwright.BrowserContext.new_page(context)

      Page.on(page, :download, fn %Event{} = event ->
        Task.start(fn ->
          download = Download.from_event(event)
          path = Download.path(download)
          send(test_pid, {:path, path})
        end)
      end)

      Page.goto(page, assets.prefix <> "/download-blob.html")
      Page.click(page, "a")

      assert_receive({:path, path}, 10_000)
      assert is_binary(path)
      assert File.exists?(path)
      assert File.read!(path) == "Hello world"

      Playwright.BrowserContext.close(context)
    end

    test "url returns download URL", %{assets: assets, browser: browser} do
      test_pid = self()

      context = Playwright.Browser.new_context(browser, %{accept_downloads: "accept"})
      page = Playwright.BrowserContext.new_page(context)

      Page.on(page, :download, fn %Event{} = event ->
        Task.start(fn ->
          download = Download.from_event(event)
          url = Download.url(download)
          send(test_pid, {:url, url})
        end)
      end)

      Page.goto(page, assets.prefix <> "/download-blob.html")
      Page.click(page, "a")

      assert_receive({:url, url}, 10_000)
      assert is_binary(url)
      # Blob URLs start with blob:
      assert String.starts_with?(url, "blob:")

      Playwright.BrowserContext.close(context)
    end
  end
end
