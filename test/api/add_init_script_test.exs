defmodule Playwright.AddInitScriptTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, Page}

  describe "Page.add_init_script/2" do
    test "returns 'subject'", %{page: page} do
      assert %Page{} = Page.add_init_script(page, "window.injected = 123")
    end

    test "evaluates before anything else on the page", %{page: page} do
      page = Page.add_init_script(page, "window.injected = 123")
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end

    test "providing `param: script` as a file path", %{page: page} do
      fixture = "test/support/fixtures/injectedfile.js"
      page = Page.add_init_script(page, %{path: fixture})
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end

    test "support for multiple scripts", %{page: page} do
      page = Page.add_init_script(page, "window.script1 = 'one'")
      page = Page.add_init_script(page, "window.script2 = 'two'")
      nil = Page.goto(page, "data:text/html,<p>some content</p>")

      assert Page.evaluate(page, "window.script1") == "one"
      assert Page.evaluate(page, "window.script2") == "two"
    end
  end

  describe "BrowserContext.add_init_script/2" do
    @tag exclude: [:page]
    test "combined with `Page.add_init_script/2`", %{browser: browser} do
      context = Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      :ok = BrowserContext.add_init_script(context, "window.temp = 123")
      page = Page.add_init_script(page, "window.injected = window.temp")
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end

    @tag exclude: [:page]
    test "providing `param: script` as a file path", %{browser: browser} do
      context = Browser.new_context(browser)
      fixture = "test/support/fixtures/injectedfile.js"
      page = BrowserContext.new_page(context)

      :ok = BrowserContext.add_init_script(context, %{path: fixture})
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end

    test "adding to the BrowserContext for an already created Page", %{page: page} do
      context = Page.owned_context(page)

      :ok = BrowserContext.add_init_script(context, "window.temp = 123")
      page = Page.add_init_script(page, "window.injected = window.temp")
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end
  end
end
