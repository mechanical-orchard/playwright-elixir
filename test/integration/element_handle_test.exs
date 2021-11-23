defmodule Playwright.ElementHandleTest do
  use Playwright.TestCase, async: true

  alias Playwright.{ElementHandle, Frame, JSHandle, Page}
  require Logger

  describe "ElementHandle fields" do
    test ":preview", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      with {:ok, outer} <- Page.q(page, "#outer"),
           {:ok, inner} <- Page.q(page, "#inner"),
           {:ok, check} <- Page.q(page, "#check"),
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
    setup :visit_button_fixture

    test "...", %{page: page} do
      case page
           |> Page.query_selector("button") do
        {:ok, button} ->
          button
          |> ElementHandle.click()
          |> assert

          result = Page.evaluate(page, "function () { return window['result']; }")
          assert result == {:ok, "Clicked"}

        {:error, :timeout} ->
          log_element_handle_error()
      end
    end
  end

  describe "ElementHandle.get_attribute/2" do
    setup :visit_dom_fixture

    test "...", %{page: page} do
      case Page.query_selector(page, "#outer") do
        {:ok, element} ->
          assert element |> ElementHandle.get_attribute("name") == {:ok, "value"}
          assert element |> ElementHandle.get_attribute("foo") == {:ok, nil}

        {:error, :timeout} ->
          log_element_handle_error()
      end
    end
  end

  describe "ElementHandle.is_visible/1" do
    test "...", %{page: page} do
      :ok = Page.set_content(page, "<div>Hi</div><span></span>")

      with {:ok, div} <- Page.q(page, "div"),
           {:ok, span} <- Page.q(page, "span") do
        assert div
        assert {:ok, true} = ElementHandle.is_visible(div)

        assert span
        assert {:ok, false} = ElementHandle.is_visible(span)
      else
        {:error, :timeout} -> log_element_handle_error()
      end
    end
  end

  describe "ElementHandle.query_selector/2" do
    setup :visit_playground_fixture

    test "...", %{page: page} do
      Page.set_content(page, """
      <html>
      <body>
        <div class="second">
          <div class="inner">A</div>
        </div>
      </body>
      </html>
      """)

      with {:ok, html} <- Page.query_selector(page, "html"),
           {:ok, second} <- ElementHandle.query_selector(html, ".second"),
           {:ok, inner_handle} <- ElementHandle.query_selector(second, ".inner") do
        assert ElementHandle.text_content(inner_handle) == {:ok, "A"}
      else
        {:error, :timeout} -> log_element_handle_error()
      end
    end
  end

  describe "ElementHandle.text_content/" do
    setup :visit_dom_fixture

    test "...", %{page: page} do
      with {:ok, handle} <- Page.q(page, "css=#inner"),
           {:ok, text} <- ElementHandle.text_content(handle) do
        assert text == "Text,\nmore text"
      else
        {:error, :timeout} -> log_element_handle_error()
      end
    end
  end

  describe "ElementHandle.content_frame/1" do
    test "returns a `Playwright.Frame`", %{assets: assets, page: page} do
      url = assets.empty
      Page.goto(page, url)

      {:ok, %Frame{} = frame} = attach_frame(page, "frame1", url)

      case Page.query_selector(page, "#frame1") do
        {:ok, handle} -> assert ElementHandle.content_frame(handle) == {:ok, frame}
        {:error, :timeout} -> log_element_handle_error()
      end
    end
  end

  # helpers
  # ---------------------------------------------------------------------------

  defp visit_button_fixture(%{assets: assets, page: page}) do
    Page.goto(page, assets.prefix <> "/input/button.html")
    [page: page]
  end

  defp visit_dom_fixture(%{assets: assets, page: page}) do
    Page.goto(page, assets.prefix <> "/dom.html")
    [page: page]
  end

  defp visit_playground_fixture(%{assets: assets, page: page}) do
    Page.goto(page, assets.prefix <> "/playground.html")
    [page: page]
  end
end
