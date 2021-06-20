defmodule Test.Features.Page.PageEvaluateHandleTest do
  use Playwright.TestCase

  describe "Page.evaluate_handle/2" do
    import Playwright.Page

    test "returns a handle of some sort", %{page: page} do
      handle = evaluate_handle(page, "function() { return window; }")
      assert is_struct(handle, Playwright.JSHandle)
    end

    test "returns a handle that can be used as an argument", %{page: page} do
      handle = evaluate_handle(page, "function() { return navigator; }")
      result = evaluate(page, "function(h) { return h.userAgent; }", handle)
      assert result =~ "Mozilla"
    end

    test "...primitive (boolean)", %{page: page} do
      handle = evaluate_handle(page, "function() { return 42; }")
      result = evaluate(page, "function(h) { return Object.is(h, 42); }", handle)
      assert result === true
    end

    test "...primitive (number)", %{page: page} do
      handle = evaluate_handle(page, "function() { return 42; }")
      result = evaluate(page, "function(n) { return n; }", handle)
      assert result === 42
    end

    test "...object", %{page: page} do
      handle = evaluate_handle(page, "function() { return { x: 1, y: 'lala' }; }")
      result = evaluate(page, "function(o) { return o; }", handle)
      assert result == %{x: 1, y: "lala"}
    end

    test "...nested object", %{page: page} do
      handle = evaluate_handle(page, "function() { return { x: 1, y: { lala: 'lulu' } }; }")
      result = evaluate(page, "function(o) { return o; }", handle)
      assert result == %{x: 1, y: %{lala: "lulu"}}
    end

    test "...nested handle (window)", %{page: page} do
      handle = evaluate_handle(page, "function() { return window; }")
      result = evaluate(page, "function(w) { return w === window; }", handle)
      assert result === true
    end

    # test "...complex nested handles", %{page: page} do
    #   one = evaluate_handle(page, "function() { return { x: 1, y: 'lala' }; }")
    #   two = evaluate_handle(page, "function() { return 42; }")
    #   yep = evaluate_handle(page, "function() { return ['lulu']; }")

    #   result =
    #     evaluate(page, "function(x) { return JSON.stringify(x); }", %{
    #       a: %{one: one},
    #       b: %{two: two, arr: [%{yep: yep}]}
    #     })

    #   assert result == "lala"
    # end

    # TODO (page/page-evaluate-handle.spec.ts):
    # - it('should throw for circular objects', async ({page}) => {
    # - it('should accept same handle multiple times', async ({page}) => {
    # - it('should accept same nested object multiple times', async ({page}) => {
    # - it('should accept object handle to unserializable value', async ({page}) => {
    # - it('should pass configurable args', async ({page}) => {

    test "...primitive write/read", %{page: page} do
      handle = evaluate_handle(page, "function() { window['LALA'] = 'LULU'; return window; }")
      result = evaluate(page, "function(h) { return h['LALA']; }", handle)
      assert result == "LULU"
    end
  end
end
