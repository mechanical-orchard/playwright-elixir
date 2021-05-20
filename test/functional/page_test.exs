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
      wait(1)

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
      wait(1)

      page
      |> Page.query_selector("css=span[role='listbox']")
      |> assert()
    end

    test ".press/2", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      # FIXME! (see note at `Page.press/3`)
      page
      |> Page.fill(".navbar__search-input", "text content")
      |> Page.press(".navbar__search-input", "Enter")
      |> Page.press(".navbar__search-input", "Enter")
      |> Page.press(".navbar__search-input", "Enter")

      assert Page.text_content(page, "css=header > h1") == "Assertions"
    end

    test ".text_content/2", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      assert Page.text_content(page, "h1.hero__title") ==
               "Playwright enables reliable end-to-end testing for modern web apps."
    end

    test ".title/1", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("https://playwright.dev")

      text = page |> Page.title()
      assert String.match?(text, ~r/Playwright$/)
    end
  end

  defp wait(seconds) do
    :timer.sleep(seconds * 1000)
  end
end
