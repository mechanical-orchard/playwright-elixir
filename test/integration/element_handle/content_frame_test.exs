defmodule Playwright.ElementHandle.ContentFrameTest do
  use Playwright.TestCase, async: true

  alias Playwright.{ElementHandle, Page}

  describe "ElementHandle.content_frame/1" do
    test "returns a `Playwright.Frame`", %{assets: assets, page: page} do
      url = assets.empty
      Page.goto(page, url)

      assert %Playwright.Frame{} = frame = attach_frame(page, "frame1", url)
      assert frame.type == "Frame"

      {:ok, handle} = Page.query_selector(page, "#frame1")
      assert %Playwright.Frame{} = content_frame = ElementHandle.content_frame(handle)
      assert content_frame.guid == frame.guid
    end
  end
end
