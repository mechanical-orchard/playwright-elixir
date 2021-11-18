defmodule Test.Features.ElementHandleTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page

  describe "...preview" do
    test "...(also found in 'convenience test' in TS)", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      {:ok, outer} = Page.q(page, "#outer")
      {:ok, inner} = Page.q(page, "#inner")
      {:ok, check} = Page.q(page, "#check")
      # child = ElementHandle.evaluate_handle(inner, "e => e.firstChild")

      assert outer.preview == ~s|JSHandle@<div id="outer" name="value">…</div>|
      assert inner.preview == ~s|JSHandle@<div id="inner">Text,↵more text</div>|
      assert check.preview == ~s|JSHandle@<input checked id="check" foo="bar"" type="checkbox"/>|
      # assert child == "JSHandle@#text=Text,↵more text"
    end
  end

  describe "click" do
    setup :visit_button_fixture

    test "click/1", %{page: page} do
      {:ok, element} = page |> Playwright.Page.query_selector("button")
      assert element |> Playwright.ElementHandle.click()

      result = Playwright.Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"
    end
  end

  describe "get_attribute" do
    setup :visit_dom_fixture

    test "get_attribute/2", %{page: page} do
      {:ok, element} = page |> Playwright.Page.query_selector("#outer")
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

      {:ok, html} = page |> Playwright.Page.query_selector("html")
      {:ok, second} = html |> Playwright.ElementHandle.query_selector(".second")
      {:ok, inner} = second |> Playwright.ElementHandle.query_selector(".inner")

      assert inner |> Playwright.ElementHandle.text_content() == "A"
    end
  end

  describe "text_content" do
    setup :visit_dom_fixture

    test "text_content/1", %{page: page} do
      {:ok, element} = page |> Playwright.Page.query_selector("css=#inner")
      assert element |> Playwright.ElementHandle.text_content() == "Text,\nmore text"
    end
  end

  # helpers
  # ----------------------------------------------------------------------------

  defp visit_button_fixture(%{assets: assets, page: page}) do
    Playwright.Page.goto(page, assets.prefix <> "/input/button.html")
    [page: page]
  end

  defp visit_dom_fixture(%{assets: assets, page: page}) do
    Playwright.Page.goto(page, assets.prefix <> "/dom.html")
    [page: page]
  end

  defp visit_playground_fixture(%{assets: assets, page: page}) do
    Playwright.Page.goto(page, assets.prefix <> "/playground.html")
    [page: page]
  end
end
