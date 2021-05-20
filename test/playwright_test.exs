defmodule PlaywrightTest do
  use ExUnit.Case
  use PlaywrightTest.Case
  doctest Playwright

  describe "Usage" do
    test "looks something like..." do
      Playwright.start()

      content =
        browser()
        |> context()
        |> page()
        |> goto("https://playwright.dev")
        |> text_content(".navbar__title")

      assert content == "Playwright"
    end
  end
end
