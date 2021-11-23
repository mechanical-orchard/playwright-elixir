defmodule Playwright.Page.LocatorTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page.Locator" do
    test "delegates to Locator (using .click/2 as an example", %{assets: assets, page: page} do
      options = %{timeout: 1_000}

      page |> Page.goto(assets.prefix <> "/empty.html")
      page |> Page.set_content("<a id='exists' target=_blank rel=noopener href='/one-style.html'>yo</a>")

      locator = Page.Locator.new(page, "a#exists")
      assert :ok = Page.Locator.click(locator, options)
    end
  end
end
