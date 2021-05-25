defmodule Playwright.Test do
  use ExUnit.Case
  use PlaywrightTest.Case
  doctest Playwright

  setup_all do
    {:ok, _} = Playwright.start()
    :ok
  end

  setup do
    # {connection, browser} = Playwright.connect("ws://localhost:3000/playwright")
    {connection, browser} = Playwright.launch()
    [browser: browser, connection: connection]
  end

  describe "Usage" do
    test "looks something like...", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()

      text =
        page
        |> Page.goto("https://playwright.dev")
        |> Page.text_content(".navbar__title")

      assert text == "Playwright"
    end
  end
end
