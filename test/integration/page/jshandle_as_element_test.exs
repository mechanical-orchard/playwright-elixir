# src: page/jshandle-as-element.spec.ts
defmodule Test.Features.Page.JSHandleAsElementTest do
  use Playwright.TestCase, async: true

  describe "JSHandle.as_element/1" do
    alias Playwright.JSHandle

    test "returns nil for non-elements", %{page: page} do
      handle = Playwright.Page.evaluate_handle(page, "function() { return 2; }")
      result = JSHandle.as_element(handle)
      refute result
    end

    test "returns an ElementHandle for DOM elements", %{page: page} do
      handle = Playwright.Page.evaluate_handle(page, "function() { return document.body; }")
      result = JSHandle.as_element(handle)
      assert is_struct(result, Playwright.ElementHandle)
    end

    test "returns an ElementHandle for text nodes", %{page: page} do
      Playwright.Page.set_content(page, "<div>lala!</div>")
      handle = Playwright.Page.evaluate_handle(page, "function() { return document.querySelector('div').firstChild; }")
      result = JSHandle.as_element(handle)
      assert is_struct(result, Playwright.ElementHandle)

      result = Playwright.Page.evaluate(page, "function(e) { return e.nodeType === Node.TEXT_NODE; }", result)
      assert result === true
    end
  end
end
