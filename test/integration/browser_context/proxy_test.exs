defmodule Playwright.BrowserContext.ProxyTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, Page, Response}

  describe "BrowserContext created with a proxy" do
    @tag exclude: [:page]
    test "uses the proxy", %{assets: assets, browser: browser} do
      context =
        Browser.new_context(browser, %{
          proxy: %{server: assets.prefix}
        })

      page = BrowserContext.new_page(context)
      response = Page.goto(page, "http://non-existent.com/assets/dom.html")

      assert Response.ok(response)
      assert Page.text_content(page, "#inner") == "Text,\nmore text"
    end

    # test_should_use_proxy_for_second_page
    # test_should_work_with_ip_port_notion
    # test_should_authenticate
    # test_should_authenticate_with_empty_password
  end
end
