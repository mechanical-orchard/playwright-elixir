defmodule Playwright.PageFrameTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Frame, Page}

  describe "Page.frame/2 by name" do
    test "finds frame by name string", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe name="my-frame" src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frame = Page.frame(page, "my-frame")

      assert %Frame{} = frame
      assert Frame.name(frame) == "my-frame"
    end

    test "finds frame by name in map", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe name="named-frame" src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frame = Page.frame(page, %{name: "named-frame"})

      assert %Frame{} = frame
      assert Frame.name(frame) == "named-frame"
    end

    test "returns nil when no frame matches name", %{page: page} do
      Page.set_content(page, "<h1>No frames</h1>")

      assert Page.frame(page, "nonexistent") == nil
    end
  end

  describe "Page.frame/2 by URL" do
    test "finds frame by exact URL", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frame = Page.frame(page, %{url: assets.empty})

      assert %Frame{} = frame
      assert frame.url == assets.empty
    end

    test "finds frame by glob pattern", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frame = Page.frame(page, %{url: "**/empty.html"})

      assert %Frame{} = frame
      assert frame.url =~ "empty.html"
    end

    test "finds frame by regex", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frame = Page.frame(page, %{url: ~r/.*empty\.html$/})

      assert %Frame{} = frame
      assert frame.url =~ "empty.html"
    end

    test "finds frame by predicate function", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frame = Page.frame(page, %{url: fn url -> String.ends_with?(url, "empty.html") end})

      assert %Frame{} = frame
      assert frame.url =~ "empty.html"
    end

    test "returns nil when no frame matches URL", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      assert Page.frame(page, %{url: "**/nonexistent.html"}) == nil
    end
  end

  describe "Page.frame/2 with multiple frames" do
    test "finds correct frame among multiple", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe name="first" src="#{assets.empty}"></iframe>
      <iframe name="second" src="#{assets.dom}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frame = Page.frame(page, "second")

      assert %Frame{} = frame
      assert Frame.name(frame) == "second"
      assert frame.url =~ "dom.html"
    end
  end
end
