defmodule Playwright.Page.EvaluateHandleTest do
  use Playwright.TestCase

  describe "Page.evaluate_handle/2" do
    alias Playwright.Page

    test "returns a JSHandle for the Window, given a function", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "function() { return window; }")
      assert is_struct(handle, Playwright.JSHandle)
      assert handle.preview == "Window"
    end

    test "returns a JSHandle for the Window, given an object reference", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "window")
      assert is_struct(handle, Playwright.JSHandle)
      assert handle.preview == "Window"
    end

    test "returns a handle that can be used as a later argument, as a handle to an object", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "function() { return navigator; }")
      {:ok, result} = Page.evaluate(page, "function(h) { return h.userAgent; }", handle)
      assert result =~ "Mozilla"
    end

    test "returns a handle that can be used as a later argument, as a handle to a primitive type", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "function() { return 42; }")

      {:ok, result} = Page.evaluate(page, "function(h) { return Object.is(h, 42); }", handle)
      assert result === true

      {:ok, result} = Page.evaluate(page, "function(n) { return n; }", handle)
      assert result === 42
    end

    test "works with a handle that references an object", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "function() { return { x: 1, y: 'lala' }; }")
      {:ok, result} = Page.evaluate(page, "function(o) { return o; }", handle)
      assert result == %{x: 1, y: "lala"}
    end

    test "works with a handle that references an object with nesting", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "function() { return { x: 1, y: { lala: 'lulu' } }; }")
      {:ok, result} = Page.evaluate(page, "function(o) { return o; }", handle)
      assert result == %{x: 1, y: %{lala: "lulu"}}
    end

    test "works with a handle that references the window", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "function() { return window; }")
      {:ok, result} = Page.evaluate(page, "function(w) { return w === window; }", handle)
      assert result === true

      {:ok, handle} = Page.evaluate_handle(page, "window")
      {:ok, result} = Page.evaluate(page, "function(w) { return w === window; }", handle)
      assert result === true
    end

    test "works with multiple nested handles", %{page: page} do
      {:ok, foo} = Page.evaluate_handle(page, "function() { return { x: 1, y: 'foo' }; }")
      {:ok, bar} = Page.evaluate_handle(page, "function() { return 5; }")
      {:ok, baz} = Page.evaluate_handle(page, "function() { return ['baz']; }")
      {:ok, bam} = Page.evaluate_handle(page, "function() { return ['bam']; }")

      {:ok, result} =
        Page.evaluate(page, "function(x) { return JSON.stringify(x); }", %{
          a1: %{foo: foo},
          a2: %{bar: bar, arr: [%{baz: baz}, %{bam: bam}]}
        })

      assert result

      assert Jason.decode!(result) == %{
               "a1" => %{
                 "foo" => %{
                   "x" => 1,
                   "y" => "foo"
                 }
               },
               "a2" => %{
                 "bar" => 5,
                 "arr" => [%{"baz" => ["baz"]}, %{"bam" => ["bam"]}]
               }
             }
    end

    # Pending (page/page-evaluate-handle.spec.ts):
    # - it('should throw for circular objects', async ({page}) => {
    # - it('should accept same handle multiple times', async ({page}) => {
    # - it('should accept same nested object multiple times', async ({page}) => {
    # - it('should accept object handle to unserializable value', async ({page}) => {
    # - it('should pass configurable args', async ({page}) => {

    test "...primitive write/read", %{page: page} do
      {:ok, handle} = Page.evaluate_handle(page, "function() { window['LALA'] = 'LULU'; return window; }")
      {:ok, result} = Page.evaluate(page, "function(h) { return h['LALA']; }", handle)
      assert result == "LULU"
    end
  end
end
