defmodule Playwright.JSHandleTest do
  use Playwright.TestCase, async: true
  alias Playwright.{ElementHandle, JSHandle, Page}

  describe "JSHandle.as_element/1" do
    test "returns `nil` for non-elements", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return 2; }")
      result = JSHandle.as_element(handle)
      refute result
    end

    test "returns an ElementHandle for DOM elements", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return document.body; }")
      result = JSHandle.as_element(handle)
      assert is_struct(result, ElementHandle)
    end

    # NOTE: review description
    test "returns an ElementHandle for DOM elements (take 2)", %{page: page} do
      handle = Page.evaluate_handle(page, "document.body")
      result = JSHandle.as_element(handle)
      assert is_struct(result, ElementHandle)
    end

    test "returns an ElementHandle for text nodes", %{page: page} do
      Page.set_content(page, "<div>lala!</div>")
      handle = Page.evaluate_handle(page, "function() { return document.querySelector('div').firstChild; }")
      result = JSHandle.as_element(handle)
      assert is_struct(result, ElementHandle)

      result = Page.evaluate(page, "function(e) { return e.nodeType === Node.TEXT_NODE; }", result)
      assert result === {:ok, true}
    end
  end
end
