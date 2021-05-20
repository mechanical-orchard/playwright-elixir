defmodule PlaywrightTest do
  use ExUnit.Case
  use PlaywrightTest.Case
  doctest Playwright

  setup do
    Playwright.start()
    [browser: browser()]
  end

  describe "Usage" do
    test "looks something like...", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()

      text =
        page
        |> goto("https://playwright.dev")
        |> text_content(".navbar__title")

      assert text == "Playwright"
    end
  end
end
