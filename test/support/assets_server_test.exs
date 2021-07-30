defmodule Test.Support.AssetsServerTest do
  use Playwright.TestCase, async: true

  describe "Local test assets derver" do
    test "works", %{assets: assets, browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/dom.html")

      page
      |> Playwright.Page.query_selector("css=div#outer")
      |> assert()
    end
  end
end
