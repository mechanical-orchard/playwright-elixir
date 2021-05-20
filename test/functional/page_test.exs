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
      # page: browser |> new_context() |> new_page()
    ]
  end

  describe "Page" do
    # @tag :skip
    # test ".query_selector/2", %{page: page} do
    #   page
    #   |> Page.query_selector("css=main")
    #   |> assert()

    #   page
    #   |> Page.query_selector("css=non-existent")
    #   |> refute()
    # end

    # test ".q/2", %{page: page} do

    # end

    # test ".$/2", %{page: page} do
    #   page
    #   |> Page."$"("css=main")
    #   |> assert()

    #   page
    #   |> Page."$"("css=non-existent")
    #   |> refute()
    # end

    @tag :skip
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

    # @tag :skip
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
      page |> Page.fill(".navbar__search-input", "text content")
      pause_for_effect()

      # TODO: "press <enter>"
    end

    # @tag :skip
    # test ".press/2", %{page: page} do
    #   page
    #   |> Page.query_selector("css=main")
    #   |> assert()

    #   page
    #   |> Page.query_selector("css=non-existent")
    #   |> refute()
    # end

    @tag :skip
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
