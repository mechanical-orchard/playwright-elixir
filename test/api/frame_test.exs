defmodule Playwright.FrameTest do
  use Playwright.TestCase, async: true

  alias Playwright.{Frame, Locator, Page}

  describe "Frame.get_by_text/3" do
    test "returns a locator that contains the given text", %{page: page} do
      Page.set_content(page, "<div><div>first</div><div>second</div><div>\nthird  </div></div>")
      frame = Page.main_frame(page)
      assert frame |> Frame.get_by_text("first") |> Locator.count() == 1

      assert frame |> Frame.get_by_text("third") |> Locator.evaluate("e => e.outerHTML") == "<div>\nthird  </div>"
      Page.set_content(page, "<div><div> first </div><div>first</div></div>")

      assert frame |> Frame.get_by_text("first", %{exact: true}) |> Locator.first() |> Locator.evaluate("e => e.outerHTML") ==
               "<div> first </div>"

      Page.set_content(page, "<div><div> first and more </div><div>first</div></div>")

      assert frame |> Frame.get_by_text("first", %{exact: true}) |> Locator.first() |> Locator.evaluate("e => e.outerHTML") ==
               "<div>first</div>"
    end
  end

  describe "Frame.highlight/2" do
    test "highlights elements matching the selector", %{page: page} do
      Page.set_content(page, ~s|<div id="target">Hello</div>|)
      frame = Page.main_frame(page)
      assert :ok = Frame.highlight(frame, "#target")
    end
  end

  describe "Frame.page/1" do
    test "returns the page containing the frame", %{page: page} do
      frame = Page.main_frame(page)
      result = Frame.page(frame)
      assert result.guid == page.guid
    end
  end
end
