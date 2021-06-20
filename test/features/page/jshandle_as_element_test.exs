# src: page/jshandle-as-element.spec.ts
defmodule Test.Features.Page.JSHandleAsElementTest do
  use Playwright.TestCase

  describe "??? .as_element/1" do
    import Playwright.JSHandle

    test "returns an ElementHandle for DOM elements", %{page: page} do
      handle = Playwright.Page.evaluate_handle(page, "function() { return document.body; }")
      result = as_element(handle)
      assert is_struct(result, Playwright.ElementHandle)
    end

    test "...nil for non-element", %{page: page} do
      handle = Playwright.Page.evaluate_handle(page, "function() { return 2; }")
      result = as_element(handle)
      refute result
    end

    test "...for text nodes", %{page: page} do
      Playwright.Page.set_content(page, "<div>lala!</div>")
      handle = Playwright.Page.evaluate_handle(page, "function() { return document.querySelector('div').firstChild; }")
      result = as_element(handle)
      assert result

      result = Playwright.Page.evaluate(page, "function(e) { return e.nodeType === Node.TEXT_NODE; }", result)
      assert result
    end
  end
end
