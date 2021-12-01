defmodule Playwright.Mimic.PyLocatorsTest do
  use Playwright.TestCase

  alias Playwright.{Locator, Page}
  # alias Playwright.Runner.Channel.Error

  # Tests that need a better home...
  describe "Mimicking Python tests in `test_locators.py`" do
    test "click_should_work", %{assets: assets, page: page} do
      locator = Page.locator(page, "button")
      page |> Page.goto(assets.prefix <> "/input/button.html")

      Locator.click(locator, %{timeout: 200})
      assert {:ok, "Clicked"} = Page.evaluate(page, "window['result']")
    end

    # NOTE: Not implemented/mimicked.
    # The matching Python test deletes `window['Node']`, but that never existed on the page.
    # test "`click_should_work_with_node_removed`"

    test "click_should_work_for_text_nodes", %{assets: assets, page: page} do
      locator = Page.locator(page, "button")
      page |> Page.goto(assets.prefix <> "/input/button.html")

      page
      |> Page.evaluate("""
      () => {
        window['double'] = false;
        const button = document.querySelector('button');
        button.addEventListener('dblclick', event => {
          window['double'] = true;
        });
      }
      """)

      Locator.dblclick(locator, %{timeout: 200})
      assert {:ok, true} = Page.evaluate(page, "window['double']")
      assert {:ok, "Clicked"} = Page.evaluate(page, "window['result']")
    end

    # NOTE: Not implemented/mimicked.
    # The matching Python implementation has results that differ from the Node.js version.
    # test "should_have_repr", %{assets: assets, page: page}
  end
end
