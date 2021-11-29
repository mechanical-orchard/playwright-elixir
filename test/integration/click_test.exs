defmodule Playwright.ClickTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page

  describe "Page.dblclick/2, mimicking Python tests" do
    test "test_locators.py: `test_double_click_the_button`", %{assets: assets, page: page} do
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

      page |> Page.dblclick("button", %{timeout: 200})
      assert {:ok, true} = Page.evaluate(page, "window['double']")
      assert {:ok, "Clicked"} = Page.evaluate(page, "window['result']")
    end
  end
end
