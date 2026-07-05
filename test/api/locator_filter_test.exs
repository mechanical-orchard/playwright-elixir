defmodule Playwright.LocatorFilterTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Locator, Page}

  describe "Locator.filter/2" do
    test "filters by has_text", %{page: page} do
      Page.set_content(page, """
        <div>Hello</div>
        <div>World</div>
      """)

      locator = Page.locator(page, "div") |> Locator.filter(has_text: "Hello")
      assert Locator.count(locator) == 1
      assert Locator.text_content(locator) == "Hello"
    end

    test "filters by has_not_text", %{page: page} do
      Page.set_content(page, """
        <div>Hello</div>
        <div>World</div>
      """)

      locator = Page.locator(page, "div") |> Locator.filter(has_not_text: "Hello")
      assert Locator.count(locator) == 1
      assert Locator.text_content(locator) == "World"
    end

    test "filters by has (nested locator)", %{page: page} do
      Page.set_content(page, """
        <div><button>Click</button></div>
        <div><span>Text</span></div>
      """)

      button = Page.locator(page, "button")
      locator = Page.locator(page, "div") |> Locator.filter(has: button)
      assert Locator.count(locator) == 1
    end

    test "filters by has_not (nested locator)", %{page: page} do
      Page.set_content(page, """
        <div><button>Click</button></div>
        <div><span>Text</span></div>
      """)

      button = Page.locator(page, "button")
      locator = Page.locator(page, "div") |> Locator.filter(has_not: button)
      assert Locator.count(locator) == 1
    end

    test "filters by visibility", %{page: page} do
      Page.set_content(page, """
        <div>Visible</div>
        <div style="display: none">Hidden</div>
      """)

      locator = Page.locator(page, "div") |> Locator.filter(visible: true)
      assert Locator.count(locator) == 1
      assert Locator.text_content(locator) == "Visible"
    end

    test "filters by visible: false", %{page: page} do
      Page.set_content(page, """
        <div>Visible</div>
        <div style="display: none">Hidden</div>
      """)

      locator = Page.locator(page, "div") |> Locator.filter(visible: false)
      assert Locator.count(locator) == 1
    end

    test "combines multiple filters", %{page: page} do
      Page.set_content(page, """
        <div><button>Submit</button></div>
        <div><button>Cancel</button></div>
        <div><span>Other</span></div>
      """)

      button = Page.locator(page, "button")

      locator =
        Page.locator(page, "div")
        |> Locator.filter(has: button, has_text: "Submit")

      assert Locator.count(locator) == 1
    end

    test "filters with regex", %{page: page} do
      Page.set_content(page, """
        <div>Hello World</div>
        <div>Goodbye World</div>
      """)

      locator = Page.locator(page, "div") |> Locator.filter(has_text: ~r/^Hello/)
      assert Locator.count(locator) == 1
    end

    test "filters with case-insensitive regex", %{page: page} do
      Page.set_content(page, """
        <div>Hello World</div>
        <div>Goodbye World</div>
      """)

      locator = Page.locator(page, "div") |> Locator.filter(has_text: ~r/^hello/i)
      assert Locator.count(locator) == 1
    end

    test "chains multiple filter calls", %{page: page} do
      Page.set_content(page, """
        <div class="item"><span>Apple</span><span class="price">$1</span></div>
        <div class="item"><span>Banana</span><span class="price">$2</span></div>
        <div class="item"><span>Cherry</span></div>
      """)

      price_span = Page.locator(page, ".price")

      locator =
        Page.locator(page, ".item")
        |> Locator.filter(has: price_span)
        |> Locator.filter(has_text: "Apple")

      assert Locator.count(locator) == 1
    end

    test "raises for unknown filter option", %{page: page} do
      Page.set_content(page, "<div>Test</div>")
      locator = Page.locator(page, "div")

      assert_raise ArgumentError, ~r/Unknown filter option/, fn ->
        Locator.filter(locator, unknown_option: "value")
      end
    end
  end
end
