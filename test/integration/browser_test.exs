defmodule Playwright.BrowserTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, Page}

  describe "Browser.new_page/1" do
    @tag exclude: [:page]
    test "builds a new Page, incl. context", %{browser: browser} do
      assert Enum.empty?(Browser.contexts(browser))

      page1 = Browser.new_page(browser)
      assert length(Browser.contexts(browser)) == 1

      page2 = Browser.new_page(browser)
      assert length(Browser.contexts(browser)) == 2

      Page.close(page1)
      assert length(Browser.contexts(browser)) == 1

      Page.close(page2)
      assert Enum.empty?(Browser.contexts(browser))
    end

    test "raises an exception upon additional call to `new_page`", %{page: page} do
      assert_raise RuntimeError, "Please use Playwright.Browser.new_context/1", fn ->
        page
        |> Playwright.Page.context()
        |> Playwright.BrowserContext.new_page()
      end
    end
  end

  describe "Browser.version/1" do
    test "returns the expected version", %{browser: browser} do
      case browser.name do
        "chromium" ->
          assert %{major: major, minor: _, patch: _} = Version.parse!(browser.version)
          assert major >= 90

        _name ->
          assert %{major: _, minor: _} = Version.parse!(browser.version)
      end
    end
  end
end
