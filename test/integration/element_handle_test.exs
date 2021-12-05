defmodule Playwright.ElementHandleTest do
  use Playwright.TestCase
  alias Playwright.{ElementHandle, Frame, JSHandle, Page}

  describe "ElementHandle" do
    test ":preview field", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      with outer <- Page.q(page, "#outer"),
           inner <- Page.q(page, "#inner"),
           check <- Page.q(page, "#check"),
           {:ok, child} <- JSHandle.evaluate_handle(inner, "e => e.firstChild") do
        assert outer.preview == ~s|JSHandle@<div id="outer" name="value">…</div>|
        assert inner.preview == ~s|JSHandle@<div id="inner">Text,↵more text</div>|
        assert check.preview == ~s|JSHandle@<input checked id="check" foo="bar"" type="checkbox"/>|
        assert child.preview == "JSHandle@#text=Text,↵more text"
      else
        {:error, :timeout} -> log_element_handle_error()
      end
    end
  end

  describe "ElementHandle.click/1" do
    test "", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")

      button = Page.query_selector(page, "button")
      assert ElementHandle.click(button) == :ok
      assert Page.evaluate(page, "function () { return window['result']; }") == "Clicked"
    end
  end

  describe "ElementHandle.get_attribute/2" do
    test "...", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      element = Page.query_selector(page, "#outer")
      assert element |> ElementHandle.get_attribute("name") == {:ok, "value"}
      assert element |> ElementHandle.get_attribute("foo") == {:ok, nil}
    end
  end

  describe "ElementHandle.is_visible/1" do
    test "...", %{page: page} do
      :ok = Page.set_content(page, "<div>Hi</div><span></span>")

      div = Page.q(page, "div")
      span = Page.q(page, "span")

      assert div
      assert {:ok, true} = ElementHandle.is_visible(div)

      assert span
      assert {:ok, false} = ElementHandle.is_visible(span)
    end
  end

  describe "ElementHandle.query_selector/2" do
    test "...", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/playground.html")

      Page.set_content(page, """
      <html>
      <body>
        <div class="second">
          <div class="inner">A</div>
        </div>
      </body>
      </html>
      """)

      assert page
             |> Page.query_selector("html")
             |> ElementHandle.query_selector(".second")
             |> ElementHandle.query_selector(".inner")
             |> ElementHandle.text_content() == "A"
    end
  end

  describe "ElementHandle.text_content/" do
    test "...", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      handle = Page.q(page, "css=#inner")
      assert ElementHandle.text_content(handle) == "Text,\nmore text"
    end
  end

  describe "ElementHandle.content_frame/1" do
    test "returns a `Playwright.Frame`", %{assets: assets, page: page} do
      url = assets.empty
      Page.goto(page, url)

      %Frame{} = frame = attach_frame(page, "frame1", url)

      handle = Page.query_selector(page, "#frame1")
      assert ElementHandle.content_frame(handle) == frame
    end
  end
end
