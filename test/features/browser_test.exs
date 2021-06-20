defmodule Test.Features.BrowserTest do
  use Playwright.TestCase

  describe "new_page/1" do
    setup :without_page_fixture

    test "creates a new Page", %{browser: browser} do
      page = Playwright.Browser.new_page(browser)
      assert page.type == "Page"
      Playwright.Page.close(page)
    end

    test "creates a new 'owned' Context for each new Page, which will be cleaned up when the Page is closed",
         %{
           browser: browser
         } do
      initial = length(Playwright.Browser.contexts(browser))

      page1 = Playwright.Browser.new_page(browser)
      assert length(Playwright.Browser.contexts(browser)) == initial + 1

      page2 = Playwright.Browser.new_page(browser)
      assert length(Playwright.Browser.contexts(browser)) == initial + 2

      Playwright.Page.close(page1)
      assert length(Playwright.Browser.contexts(browser)) == initial + 1

      Playwright.Page.close(page2)
      assert length(Playwright.Browser.contexts(browser)) == initial
    end

    test "enforces 1-to-1 on Page and Context", %{browser: browser} do
      page = Playwright.Browser.new_page(browser)

      assert_raise RuntimeError, "Please use Playwright.Browser.new_context/1", fn ->
        page
        |> Playwright.Page.context()
        |> Playwright.BrowserContext.new_page()
      end
    end
  end

  describe "version/1" do
    setup :without_page_fixture

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

  defp without_page_fixture(%{page: page}) do
    Playwright.Page.close(page)
    :timer.sleep(10)
    :ok
  end
end
