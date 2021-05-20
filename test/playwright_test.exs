defmodule PlaywrightTest do
  use ExUnit.Case
  use PlaywrightTest.Case
  doctest Playwright

  setup do
    Playwright.start()
    {connection, browser} = connect()
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

      pause_for_effect()
      assert text == "Playwright"
    end
  end

  describe "Page" do
    test ".close", %{browser: browser, connection: connection} do
      page =
        browser
        |> new_context()
        |> new_page()

      Playwright.Client.Connection.has(connection, page.guid)
      |> assert()

      pause_for_effect()
      page |> Page.close()

      Playwright.Client.Connection.has(connection, page.guid)
      |> refute()
    end
  end

  defp pause_for_effect() do
    # :timer.sleep(2000)
  end
end
