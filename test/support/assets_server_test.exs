defmodule Test.Support.AssetsServerTest do
  use Playwright.TestCase
  alias Playwright.{Page, Response}

  describe "Embedded test assets server" do
    test "using the 'canonical' assets", %{assets: assets, page: page} do
      assert page
             |> Page.goto(assets.prefix <> "/dom.html")
             |> Response.ok()

      page
      |> Page.query_selector("css=div#outer")
      |> assert()
    end

    test "using 'extra' assets", %{assets: assets, page: page} do
      assert page
             |> Page.goto(assets.extras <> "/example.html")
             |> Response.ok()
    end
  end
end
