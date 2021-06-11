defmodule Test.Support.AssetsServerTest do
  use Playwright.TestCase

  describe "Local test assets derver" do
    test "works", %{assets: assets, browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/dom.html")

      page
      |> Page.query_selector("css=div#outer")
      |> assert()
    end
  end
end
