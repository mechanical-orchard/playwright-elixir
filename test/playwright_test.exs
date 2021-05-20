defmodule PlaywrightTest do
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

  @tag :skip
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
    @tag :skip
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

    test ".click", %{browser: browser} do
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

    @tag :skip
    test ".title", %{browser: browser} do
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

  defp pause_for_effect() do
    :timer.sleep(2000)
  end
end
