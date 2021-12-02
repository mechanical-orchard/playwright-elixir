defmodule Playwright.AddInitScriptTest do
  use Playwright.TestCase
  alias Playwright.{Browser, BrowserContext, Page}

  describe "Page.add_init_script/2" do
    test "evaluates before anything else on the page", %{page: page} do
      page |> Page.add_init_script("window.injected = 123")
      page |> Page.goto("data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate!(page, "window.result") == 123
    end

    test "providing `param: script` as a file path", %{assets: assets, page: page} do
      page |> Page.add_init_script(%{path: assets.path <> "/injectedfile.js"})
      page |> Page.goto("data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate!(page, "window.result") == 123
    end

    test "support for multiple scripts", %{page: page} do
      page |> Page.add_init_script("window.script1 = 'one'")
      page |> Page.add_init_script("window.script2 = 'two'")
      page |> Page.goto("data:text/html,<p>some content</p>")

      assert Page.evaluate!(page, "window.script1") == "one"
      assert Page.evaluate!(page, "window.script2") == "two"
    end
  end

  describe "BrowserContext.add_init_script/2" do
    @tag exclude: [:page]
    test "combined with `Page.add_init_script/2`", %{browser: browser} do
      {:ok, context} = Browser.new_context(browser)
      {:ok, page} = BrowserContext.new_page(context)

      context |> BrowserContext.add_init_script("window.temp = 123")
      page |> Page.add_init_script("window.injected = window.temp")
      page |> Page.goto("data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate!(page, "window.result") == 123
    end

    @tag exclude: [:page]
    test "providing `param: script` as a file path", %{assets: assets, browser: browser} do
      {:ok, context} = Browser.new_context(browser)
      {:ok, page} = BrowserContext.new_page(context)

      context |> BrowserContext.add_init_script(%{path: assets.path <> "/injectedfile.js"})
      page |> Page.goto("data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate!(page, "window.result") == 123
    end

    test "adding to the BrowserContext for an already created Page", %{page: page} do
      context = Page.owned_context(page)

      context |> BrowserContext.add_init_script("window.temp = 123")
      page |> Page.add_init_script("window.injected = window.temp")
      page |> Page.goto("data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate!(page, "window.result") == 123
    end
  end
end
