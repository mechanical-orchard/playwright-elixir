defmodule Playwright.BrowserContext.AddCookiesTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page}

  describe "BrowserContext.add_cookies/2" do
    test "returns 'subject'", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      cookies = [%{url: assets.empty, name: "password", value: "123456"}]
      assert %BrowserContext{} = BrowserContext.add_cookies(context, cookies)
    end

    test "adds cookies, readable by Page", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      page |> Page.goto(assets.empty)

      context
      |> BrowserContext.add_cookies([
        %{url: assets.empty, name: "password", value: "123456"}
      ])

      assert Page.evaluate(page, "() => document.cookie") == "password=123456"
    end

    # test_should_roundtrip_cookie
    # test_should_send_cookie_header
    # test_should_isolate_cookies_in_browser_contexts
    # test_should_isolate_session_cookies
    # test_should_isolate_persistent_cookies
    # test_should_isolate_send_cookie_header
    # test_should_isolate_cookies_between_launches
    # test_should_set_multiple_cookies
    # test_should_have_expires_set_to_neg_1_for_session_cookies
    # test_should_set_cookie_with_reasonable_defaults
    # test_should_set_a_cookie_with_a_path
    # test_should_not_set_a_cookie_with_blank_page_url
    # test_should_not_set_a_cookie_on_a_data_url_page
    # test_should_default_to_setting_secure_cookie_for_https_websites
    # test_should_be_able_to_set_unsecure_cookie_for_http_website
    # test_should_set_a_cookie_on_a_different_domain
    # test_should_set_cookies_for_a_frame
    # test_should_not_block_third_party_cookies
  end

  describe "BrowserContext.add_cookies!/2" do
    test "on success, returns 'subject", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      cookies = [%{url: assets.empty, name: "password", value: "123456"}]
      assert %BrowserContext{} = BrowserContext.add_cookies(context, cookies)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "cookies[0].name: expected string, got undefined", fn ->
        context = Page.owned_context(page)
        BrowserContext.add_cookies!(context, [%{bogus: "cookie"}])
      end
    end
  end
end
