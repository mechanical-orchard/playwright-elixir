defmodule Test.ExampleTest do
  use ExUnit.Case, async: true
  use PlaywrightTest.Case
  alias Playwright.{Browser, Page, Response}

  describe "Playwright.launch/0" do
    test "returns the default browser" do
      assert Playwright.launch()
             |> Browser.new_page()
             |> Page.goto("http://example.com")
             |> Response.ok()
    end
  end

  describe "Playwright.launch/1" do
    test "returns the requested browser" do
      assert Playwright.launch(:chromium)
             |> Browser.new_page()
             |> Page.goto("http://example.com")
             |> Response.ok()
    end
  end

  describe "PlaywrightTest.Case context" do
    test "using `:browser`", %{browser: browser} do
      assert browser
             |> Browser.new_page()
             |> Page.goto("http://example.com")
             |> Response.ok()
    end

    test "using `:page`", %{page: page} do
      assert page
             |> Page.goto("http://example.com")
             |> Response.ok()
    end

    @tag exclude: [:page]
    test "excluding `:page` via `@tag`", context do
      assert Map.has_key?(context, :browser)
      refute Map.has_key?(context, :page)
    end
  end
end
