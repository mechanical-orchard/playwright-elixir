defmodule Playwright.ElementHandle.ContentFrameTest do
  use Playwright.TestCase, async: true

  alias Playwright.{ElementHandle, Page}

  describe "ElementHandle.content_frame/1" do
    test "returns a `Playwright.Frame`", %{assets: assets, page: page} do
      url = assets.empty
      Page.goto(page, url)

      frame = attach_frame(page, "frame1", url)
      assert frame.type == "Frame"

      handle = Page.query_selector(page, "#frame1")
      assert ElementHandle.content_frame(handle) == frame
    end
  end
end
