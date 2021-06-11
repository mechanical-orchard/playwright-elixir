defmodule Test.ExampleTest do
  @moduledoc """
  Use this `Test.ExampleTest` as a simple example of writing tests using
  [`playwright-elixir`](https://github.com/geometerio/playwright-elixir).
  """
  use Playwright.TestCase

  describe "Usage against a public domain" do
    test "works", %{browser: browser} do
      page =
        browser
        |> Browser.new_page()

      text =
        page
        |> Page.goto("https://playwright.dev")
        |> Page.text_content(".navbar__title")

      assert text == "Playwright"

      Page.close(page)
    end
  end

  describe "Usage against the local server" do
    test "works (using the playwright assets server)", %{assets: assets, browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/dom.html")

      page
      |> Page.query_selector("css=div#outer")
      |> assert()

      Page.close(page)
    end
  end
end
