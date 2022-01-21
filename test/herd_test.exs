defmodule Example.Test.Herd do
  use ExUnit.Case, async: true
  use PlaywrightTest.Case
  alias Playwright.{Browser, Page, Response}

  test "joins and becomes a speaker" do
    page =
      Playwright.launch()
      |> Browser.new_page()

    page |> Page.goto("https://together.horse/rooms/atg-daily/5690-qqtu-1867")

    :ok =
      page
      |> Playwright.Page.Locator.new("[data-phx-main].phx-connected")
      |> Playwright.Frame.Locator.wait_for()

    page
    |> Playwright.Page.fill("[test-role=participant-name]", "participant-1")

    page
    |> Playwright.Page.Locator.new("[test-role=join-button]")
    |> Playwright.Page.Locator.click()

    :ok =
      page
      |> Playwright.Page.Locator.new("[data-phx-main].phx-connected")
      |> Playwright.Frame.Locator.wait_for()

    # Wait for and toggle video on
    :ok =
      page
      |> Playwright.Page.Locator.new("[test-role='camera-control-toggle'] input[type=checkbox]:not(:checked)")
      |> Playwright.Frame.Locator.wait_for(%{state: "attached"})

    :ok =
      page
      |> Playwright.Page.Locator.new("[test-role='camera-control-toggle']")
      |> Playwright.Page.Locator.click()

    # Linger
    :timer.sleep(:timer.seconds(10))

    Playwright.Page.close(page)
  end
end
