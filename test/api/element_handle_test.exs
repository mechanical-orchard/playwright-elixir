defmodule Playwright.ElementHandleTest do
  use Playwright.TestCase, async: true
  alias Playwright.{ElementHandle, Frame, JSHandle, Page}

  describe "ElementHandle" do
    test ":preview field", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      with %ElementHandle{} = outer <- Page.q(page, "#outer"),
           %ElementHandle{} = inner <- Page.q(page, "#inner"),
           %ElementHandle{} = check <- Page.q(page, "#check"),
           %ElementHandle{} = child <- JSHandle.evaluate_handle(inner, "e => e.firstChild") do
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
    test "returns 'subject'", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")
      button = Page.query_selector(page, "button")
      assert %ElementHandle{} = ElementHandle.click(button)
    end

    test "...", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")

      Page.query_selector(page, "button")
      |> ElementHandle.click()

      assert Page.evaluate(page, "function () { return window['result']; }") == "Clicked"
    end
  end

  describe "ElementHandle.get_attribute/2" do
    test "...", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      element = Page.query_selector(page, "#outer")
      assert element |> ElementHandle.get_attribute("name") == "value"
      assert element |> ElementHandle.get_attribute("foo") == nil
    end
  end

  describe "ElementHandle.is_visible/1" do
    test "...", %{page: page} do
      :ok = Page.set_content(page, "<div>Hi</div><span></span>")

      div = Page.q(page, "div")
      span = Page.q(page, "span")

      assert div
      assert ElementHandle.is_visible(div) === true

      assert span
      assert ElementHandle.is_visible(span) === false
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
