defmodule Playwright.FrameHierarchyTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Frame, Page}

  describe "Frame.page/1" do
    test "returns the page for main frame", %{page: page} do
      frame = Page.main_frame(page)
      assert Frame.page(frame).guid == page.guid
    end

    test "returns the page for iframe", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/frames/one-frame.html")
      frames = Page.frames(page)
      child = Enum.find(frames, fn f -> f.url =~ "frame.html" end)

      assert Frame.page(child).guid == page.guid
    end
  end

  describe "Frame.parent_frame/1" do
    test "returns nil for main frame", %{page: page} do
      frame = Page.main_frame(page)
      assert Frame.parent_frame(frame) == nil
    end

    test "returns parent for iframe", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/frames/one-frame.html")
      # Wait for page to fully load including iframe
      Page.wait_for_load_state(page, "load")

      frames = Page.frames(page)
      # Match specifically the iframe URL (ends with /frame.html, not /one-frame.html)
      child = Enum.find(frames, fn f -> String.ends_with?(f.url, "/frame.html") end)

      assert child != nil
      parent = Frame.parent_frame(child)
      assert parent != nil
      assert parent.guid == Page.main_frame(page).guid
    end
  end

  describe "Frame.child_frames/1" do
    test "returns empty for page with no iframes", %{page: page} do
      Page.set_content(page, "<h1>No frames</h1>")
      frame = Page.main_frame(page)
      assert Frame.child_frames(frame) == []
    end

    test "returns children for parent frame", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/frames/one-frame.html")
      main = Page.main_frame(page)
      children = Frame.child_frames(main)

      assert length(children) == 1
      assert hd(children).url =~ "frame.html"
    end

    test "returns multiple children for nested frames page", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/frames/two-frames.html")
      main = Page.main_frame(page)
      children = Frame.child_frames(main)

      assert length(children) == 2
    end
  end

  describe "Frame.name/1" do
    test "returns empty string for unnamed frame", %{page: page} do
      frame = Page.main_frame(page)
      # Main frame typically has no name
      assert Frame.name(frame) == "" || Frame.name(frame) == nil
    end
  end

  describe "Frame.is_detached/1" do
    test "returns false for attached frame", %{page: page} do
      frame = Page.main_frame(page)
      assert Frame.is_detached(frame) == false
    end

    test "returns false for attached iframe", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/frames/one-frame.html")
      frames = Page.frames(page)
      child = Enum.find(frames, fn f -> f.url =~ "frame.html" end)

      assert Frame.is_detached(child) == false
    end
  end
end
