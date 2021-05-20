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

    [
      connection: connection,
      browser: browser
    ]
  end

  describe "Page" do
    test ".query_selector/2", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      page
      |> Page.query_selector("css=main")
      |> assert()

      page
      |> Page.query_selector("css=non-existent")
      |> refute()
    end

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

      # FIXME!
      pause_for_effect(1)

      text = page |> Page.title()
      assert text == "Getting Started | Playwright"
    end

    test ".fill/3", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      page
      |> Page.query_selector("css=span[role='listbox']")
      |> refute()

      page |> Page.fill(".navbar__search-input", "text content")

      # FIXME!
      pause_for_effect(1)

      page
      |> Page.query_selector("css=span[role='listbox']")
      |> assert()
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

  defp pause_for_effect(seconds \\ 0) do
    :timer.sleep(seconds * 1000)
  end
end
