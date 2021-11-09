defmodule Test.BrowserContext.DefaultTest do
  use Playwright.TestCase, async: true

  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.Page
  alias Playwright.Request

  require Logger

  describe "supported options" do
    @tag exclude: [:page]
    test "extraHTTPHeaders", %{assets: assets, browser: browser} do
      params = %{extra_http_headers: %{foo: "bar", another: "one"}}

      request =
        browser
        |> Browser.new_context(params)
        |> BrowserContext.new_page()
        |> Page.goto(assets.prefix <> "/empty.html")
        |> Request.for_response()

      assert Request.get_header(request, "foo").value == "bar"
      assert Request.get_header(request, "another").value == "one"
    end
  end
end
