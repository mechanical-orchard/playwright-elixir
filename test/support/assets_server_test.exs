defmodule Test.Support.AssetsServerTest do
  use Playwright.TestCase

  describe "Local test assets derver" do
    test "works", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/dom.html")

      page
      |> Page.query_selector("css=div#outer")
      |> assert()
    end
  end
end
