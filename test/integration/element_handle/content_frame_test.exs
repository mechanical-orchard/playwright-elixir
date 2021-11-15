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

# def test_content_frame_for_non_iframes(
#     page: Page, server: Server, utils: Utils
# ) -> None:
#     page.goto(server.EMPTY_PAGE)
#     utils.attach_frame(page, "frame1", server.EMPTY_PAGE)
#     frame = page.frames[1]
#     element_handle = frame.evaluate_handle("document.body").as_element()
#     assert element_handle
#     assert element_handle.content_frame() is None

# def test_content_frame_for_document_element(
#     page: Page, server: Server, utils: Utils
# ) -> None:
#     page.goto(server.EMPTY_PAGE)
#     utils.attach_frame(page, "frame1", server.EMPTY_PAGE)
#     frame = page.frames[1]
#     element_handle = frame.evaluate_handle("document.documentElement").as_element()
#     assert element_handle
#     assert element_handle.content_frame() is None
