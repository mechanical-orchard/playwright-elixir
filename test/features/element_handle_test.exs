defmodule Test.Features.ElementHandleTest do
  use Playwright.TestCase

  describe "click" do
    setup :visit_button_fixture

    test "click/1", %{page: page} do
      element = page |> Playwright.Page.query_selector("button")
      assert element |> Playwright.ElementHandle.click()

      result = Playwright.Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"
    end
  end

  describe "get_attribute" do
    setup :visit_dom_fixture

    test "get_attribute/2", %{page: page} do
      element = page |> Playwright.Page.query_selector("#outer")
      assert element |> Playwright.ElementHandle.get_attribute("name") == "value"
      assert element |> Playwright.ElementHandle.get_attribute("foo") == nil
    end

    test "Page delegates to this get_attribute", %{page: page} do
      assert Playwright.Page.get_attribute(page, "#outer", "name") == "value"
      assert Playwright.Page.get_attribute(page, "#outer", "foo") == nil
    end
  end

  describe "query_selector" do
    setup :visit_playground_fixture

    test "query_selector/2", %{page: page} do
      page
      |> Playwright.Page.set_content(~S[<html><body><div class="second"><div class="inner">A</div></div></body></html>])

      html = page |> Playwright.Page.query_selector("html")
      second = html |> Playwright.ElementHandle.query_selector(".second")
      inner = second |> Playwright.ElementHandle.query_selector(".inner")

      assert inner |> Playwright.ElementHandle.text_content() == "A"
    end
  end

  describe "text_content" do
    setup :visit_dom_fixture

    test "text_content/1", %{page: page} do
      assert page
             |> Playwright.Page.query_selector("css=#inner")
             |> Playwright.ElementHandle.text_content() == "Text,\nmore text"
    end
  end

  # helpers
  # ----------------------------------------------------------------------------

  defp visit_button_fixture(%{assets: assets, page: page}) do
    [page: Playwright.Page.goto(page, assets.prefix <> "/input/button.html")]
  end

  defp visit_dom_fixture(%{assets: assets, page: page}) do
    [page: Playwright.Page.goto(page, assets.prefix <> "/dom.html")]
  end

  defp visit_playground_fixture(%{assets: assets, page: page}) do
    [page: Playwright.Page.goto(page, assets.prefix <> "/playground.html")]
  end
end
