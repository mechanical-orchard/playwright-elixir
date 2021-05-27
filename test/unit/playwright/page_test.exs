defmodule Playwright.PageTest do
  use ExUnit.Case
  use PlaywrightTest.Case

  describe "Usage" do
    test "against the local test assets server", %{browser: browser, server: server} do
      IO.inspect(server)

      page =
        browser
        |> BrowserType.new_context()
        |> BrowserContext.new_page()
        |> Page.goto(server.prefix <> "/dom.html")

      page
      |> Page.query_selector("css=div#outer")
      |> assert()
    end
  end
end
