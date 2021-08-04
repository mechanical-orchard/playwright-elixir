defmodule Test.ExampleTest do
  @moduledoc """
  Use this `Test.ExampleTest` as a simple example of writing tests using
  [`playwright-elixir`](https://github.com/geometerio/playwright-elixir).
  """
  use ExUnit.Case, async: true
  use PlaywrightTest.Case

  describe "Usage against a public domain" do
    test "works", %{browser: browser} do
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
  end
end
