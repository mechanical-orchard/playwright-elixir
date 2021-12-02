defmodule Playwright.BrowserContext.CookiesTest do
  use Playwright.TestCase
  alias Playwright.{BrowserContext, Page}

  describe "BrowserContext.cookies/1" do
    test "retrieves no cookies from a pristine context", %{page: page} do
      cookies = BrowserContext.cookies(page.owned_context)
      assert cookies == {:ok, []}
    end

    test "retrieves cookies for the context", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      page |> Page.goto(assets.empty)

      cookie =
        page
        |> Page.evaluate!("""
          () => {
            document.cookie = "username=Jane";
            return document.cookie;
          }
        """)

      assert cookie == "username=Jane"

      assert BrowserContext.cookies(context) == {
               :ok,
               [
                 %{
                   domain: "localhost",
                   expires: -1,
                   httpOnly: false,
                   name: "username",
                   path: "/",
                   sameSite: "Lax",
                   secure: false,
                   value: "Jane"
                 }
               ]
             }
    end

    # test_should_get_a_non_session_cookie
    # test_should_properly_report_httpOnly_cookie
    # test_should_properly_report_strict_sameSite_cookie
    # test_should_properly_report_lax_sameSite_cookie
    # test_should_get_multiple_cookies
    # test_should_get_cookies_from_multiple_urls
  end
end
