defmodule Playwright.FrameTest do
  use Playwright.TestCase, async: true
  alias Playwright.{ElementHandle, Frame, Locator, Page}

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

  describe "Frame.click/3" do
    test "with a button inside an iframe", %{assets: assets, page: page} do
      %Page{} = Page.set_content(page, "<div style='width:100px; height:100px'>spacer</div>")
      frame = attach_frame(page, "button-test", assets.prefix <> "/input/button.html")

      Frame.query_selector(frame, "button")
      |> ElementHandle.click()

      assert Frame.evaluate(frame, "window.result") == "Clicked"
    end
  end
end
