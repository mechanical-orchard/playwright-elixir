defmodule Playwright.VideoTest do
  use Playwright.TestCase, async: false
  alias Playwright.{Browser, BrowserContext, Page, Video}

  describe "Video recording" do
    test "saves video to file", %{browser: browser} do
      context = Browser.new_context(browser, %{record_video: %{dir: System.tmp_dir!()}})
      page = BrowserContext.new_page(context)

      # Navigate to a page with content and set a visible background to trigger frame capture
      Page.goto(page, "data:text/html,<html><body><h1>Test</h1></body></html>")
      Page.evaluate(page, "() => document.body.style.backgroundColor = 'red'")
      # Wait for frames to be captured
      Process.sleep(200)

      BrowserContext.close(context)

      video = Page.video(page)
      assert video != nil

      save_path = Path.join(System.tmp_dir!(), "test_video_#{:rand.uniform(100_000)}.webm")
      assert :ok = Video.save_as(video, save_path)
      assert File.exists?(save_path)

      File.rm(save_path)
    end

    test "returns nil when video not enabled", %{page: page} do
      # For pages without video recording, should return nil quickly
      assert Page.video(page) == nil
    end

    test "delete removes video", %{browser: browser} do
      context = Browser.new_context(browser, %{record_video: %{dir: System.tmp_dir!()}})
      page = BrowserContext.new_page(context)

      Page.goto(page, "data:text/html,<html><body><h1>Test</h1></body></html>")
      Page.evaluate(page, "() => document.body.style.backgroundColor = 'blue'")
      Process.sleep(200)

      BrowserContext.close(context)

      video = Page.video(page)
      assert video != nil
      assert :ok = Video.delete(video)
    end

    test "path returns video file path", %{browser: browser} do
      context = Browser.new_context(browser, %{record_video: %{dir: System.tmp_dir!()}})
      page = BrowserContext.new_page(context)

      Page.goto(page, "data:text/html,<html><body><h1>Test</h1></body></html>")
      Page.evaluate(page, "() => document.body.style.backgroundColor = 'green'")
      Process.sleep(200)

      BrowserContext.close(context)

      video = Page.video(page)
      assert video != nil

      path = Video.path(video)
      assert is_binary(path)
      assert String.ends_with?(path, ".webm")
    end
  end
end
