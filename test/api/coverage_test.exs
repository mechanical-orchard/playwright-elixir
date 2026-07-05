defmodule Playwright.CoverageTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Coverage, Page}

  describe "Coverage.start_js_coverage/2 and stop_js_coverage/1" do
    test "collects JavaScript coverage", %{page: page} do
      :ok = Coverage.start_js_coverage(page)
      Page.goto(page, "data:text/html,<script>function test() { return 1; } test();</script>")
      entries = Coverage.stop_js_coverage(page)
      assert is_list(entries)
    end

    test "accepts options", %{page: page} do
      :ok = Coverage.start_js_coverage(page, %{reset_on_navigation: false})
      Page.set_content(page, "<script>var x = 1;</script>")
      entries = Coverage.stop_js_coverage(page)
      assert is_list(entries)
    end
  end

  describe "Coverage.start_css_coverage/2 and stop_css_coverage/1" do
    test "collects CSS coverage", %{page: page} do
      :ok = Coverage.start_css_coverage(page)
      Page.goto(page, "data:text/html,<style>body { color: red; }</style>")
      entries = Coverage.stop_css_coverage(page)
      assert is_list(entries)
    end

    test "accepts options", %{page: page} do
      :ok = Coverage.start_css_coverage(page, %{reset_on_navigation: false})
      Page.set_content(page, "<style>.test { display: none; }</style>")
      entries = Coverage.stop_css_coverage(page)
      assert is_list(entries)
    end
  end
end
