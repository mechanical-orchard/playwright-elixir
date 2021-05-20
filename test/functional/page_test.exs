defmodule Playwright.Test.Functional.PageTest do
  use ExUnit.Case
  use PlaywrightTest.Case
  doctest Playwright

  setup_all do
    {:ok, _} = Playwright.start()
    :ok
  end

  setup do
    {connection, browser} = connect()
    [browser: browser, connection: connection]
  end

  describe "Page" do
    test ".close/1", %{browser: browser, connection: connection} do
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

    test ".click/2", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      page |> Page.click("text=Get started")

      pause_for_effect()

      text = page |> Page.title()
      assert text == "Getting Started | Playwright"
    end

    # NOTE: This one is not yet working. The equivalent test works in
    # TypeScript, and `.click` works to focus the field. So, it must be
    # time to handle some more websocket messages/events.
    @tag :skip
    test ".fill/3", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      page |> Page.click(".navbar__search-input")
      pause_for_effect()
      page |> Page.fill(".navbar__search-input", "some text")
      pause_for_effect()

      # TODO: "press <enter>"
    end

    test ".title/1", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      pause_for_effect()

      text = page |> Page.title()
      assert String.match?(text, ~r/Playwright$/)
    end
  end

  defp pause_for_effect(seconds \\ 2) do
    :timer.sleep(seconds * 1000)
  end
end
