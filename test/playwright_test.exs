defmodule Playwright.Test do
  use ExUnit.Case
  use PlaywrightTest.Case
  doctest Playwright

  describe "Usage" do
    test "against a public domain", %{browser: browser} do
      page =
        browser
        |> BrowserType.new_context()
        |> BrowserContext.new_page()

      text =
        page
        |> Page.goto("https://playwright.dev")
        |> Page.text_content(".navbar__title")

      assert text == "Playwright"
    end

    test "against the local test assets server", %{browser: browser} do
      page =
        browser
        |> BrowserType.new_context()
        |> BrowserContext.new_page()
        |> Page.goto("http://localhost:3002/dom.html")

      page
      |> Page.query_selector("css=div#outer")
      |> assert()
    end
  end
end
