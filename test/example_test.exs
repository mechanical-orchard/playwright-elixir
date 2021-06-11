defmodule Test.ExampleTest do
  use ExUnit.Case

  use PlaywrightTest.Case,
    transport: :websocket,
    playwright_endpoint: "ws://localhost:3000/chromium"

  require Logger

  describe "Usage" do
    test "against a public domain", %{browser: browser} do
      Logger.debug("Testing 'playwright.dev'")

      page =
        browser
        |> Browser.new_page()

      text =
        page
        |> Page.goto("https://playwright.dev")
        |> Page.text_content(".navbar__title")

      assert text == "Playwright"

      Page.close(page)
    end

    test "against the local test assets server", %{browser: browser} do
      server = %{prefix: "http://playwright-assets:3002"}
      Logger.debug("Testing #{inspect(server.prefix)}")

      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/dom.html")

      page
      |> Page.query_selector("css=div#outer")
      |> assert()

      Page.close(page)
    end
  end
end
