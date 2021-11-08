defmodule Test.ExampleTest do
  @moduledoc """
  `Test.ExampleTest` provides a a simple example of writing tests using
  [`playwright-elixir`](https://github.com/geometerio/playwright-elixir).
  """
  use ExUnit.Case, async: true
  use PlaywrightTest.Case

  describe "An example test against playwright.dev" do
    test "using `browser` from test context", %{browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()

      text =
        page
        |> Playwright.Page.goto("https://playwright.dev")
        |> Playwright.Page.text_content(".navbar__title")

      assert text == "Playwright"

      Playwright.Page.close(page)
    end

    test "using `page` from test context", %{page: page} do
      text =
        page
        |> Playwright.Page.goto("https://playwright.dev")
        |> Playwright.Page.text_content(".navbar__title")

      assert text == "Playwright"
    end

    @tag exclude: [:page]
    test "excluding `page` context via `@tag` (useful when explicitly managing instance lifecycle)", context do
      refute Map.has_key?(context, :page)
    end
  end
end
