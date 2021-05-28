defmodule Playwright.Test.Support.AssetsServerTest do
  use ExUnit.Case
  use PlaywrightTest.Case

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
