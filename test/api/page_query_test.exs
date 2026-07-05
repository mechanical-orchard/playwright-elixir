defmodule Playwright.PageQueryTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page query methods" do
    test "inner_text/3", %{page: page} do
      Page.set_content(page, "<div id=\"target\">Hello <span>World</span></div>")
      assert Page.inner_text(page, "#target") == "Hello World"
    end

    test "inner_html/3", %{page: page} do
      Page.set_content(page, "<div id=\"target\">Hello <span>World</span></div>")
      assert Page.inner_html(page, "#target") == "Hello <span>World</span>"
    end

    test "input_value/3", %{page: page} do
      Page.set_content(page, "<input id=\"target\" value=\"test value\">")
      assert Page.input_value(page, "#target") == "test value"
    end

    test "is_checked/3", %{page: page} do
      Page.set_content(page, "<input type=\"checkbox\" id=\"target\" checked>")
      assert Page.is_checked(page, "#target") == true
    end

    test "is_disabled/3", %{page: page} do
      Page.set_content(page, "<button id=\"target\" disabled>Click</button>")
      assert Page.is_disabled(page, "#target") == true
    end

    test "is_editable/3", %{page: page} do
      Page.set_content(page, "<input id=\"target\">")
      assert Page.is_editable(page, "#target") == true
    end

    test "is_enabled/3", %{page: page} do
      Page.set_content(page, "<button id=\"target\">Click</button>")
      assert Page.is_enabled(page, "#target") == true
    end

    test "is_hidden/3", %{page: page} do
      Page.set_content(page, "<div id=\"target\" style=\"display:none\">Hidden</div>")
      assert Page.is_hidden(page, "#target") == true
    end

    test "is_visible/3", %{page: page} do
      Page.set_content(page, "<div id=\"target\">Visible</div>")
      assert Page.is_visible(page, "#target") == true
    end
  end
end
