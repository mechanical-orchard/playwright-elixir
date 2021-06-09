defmodule Test.ExampleTest do
  use Playwright.TestCase

  describe "Usage" do
    test "against a public domain", %{browser: browser} do
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

    test "against the local test assets server", %{server: server, browser: browser} do
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
