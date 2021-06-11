defmodule Test.Features.ElementHandleTest do
  use Playwright.TestCase

  alias Playwright.ChannelOwner.ElementHandle

  def visit_button_fixture(%{assets: assets, browser: browser}) do
    page =
      browser
      |> Browser.new_page()
      |> Page.goto(assets.prefix <> "/input/button.html")

    [page: page]
  end

  def visit_dom_fixture(%{assets: assets, browser: browser}) do
    page =
      browser
      |> Browser.new_page()
      |> Page.goto(assets.prefix <> "/dom.html")

    [page: page]
  end

  def visit_playground_fixture(%{assets: assets, browser: browser}) do
    page =
      browser
      |> Browser.new_page()
      |> Page.goto(assets.prefix <> "/playground.html")

    [page: page]
  end

  describe "click" do
    setup :visit_button_fixture

    test "click/1", %{page: page} do
      element = page |> Page.query_selector("button")
      assert element |> ElementHandle.click()

      result = Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"

      Page.close(page)
    end
  end

  describe "get_attribute" do
    setup :visit_dom_fixture

    test "get_attribute/2", %{page: page} do
      element = page |> Page.query_selector("#outer")
      assert element |> ElementHandle.get_attribute("name") == "value"
      assert element |> ElementHandle.get_attribute("foo") == nil

      Page.close(page)
    end

    test "Page delegates to this get_attribute", %{page: page} do
      assert Page.get_attribute(page, "#outer", "name") == "value"
      assert Page.get_attribute(page, "#outer", "foo") == nil

      Page.close(page)
    end
  end

  describe "query_selector" do
    setup :visit_playground_fixture

    test "query_selector/2", %{page: page} do
      page |> Page.set_content(~S[<html><body><div class="second"><div class="inner">A</div></div></body></html>])
      html = page |> Page.query_selector("html")
      second = html |> ElementHandle.query_selector(".second")
      inner = second |> ElementHandle.query_selector(".inner")

      assert inner |> ElementHandle.text_content() == "A"

      Page.close(page)
    end
  end

  describe "text_content" do
    setup :visit_dom_fixture

    test "text_content/1", %{page: page} do
      assert page
             |> Page.query_selector("css=#inner")
             |> ElementHandle.text_content() == "Text,\nmore text"

      Page.close(page)
    end
  end
end
