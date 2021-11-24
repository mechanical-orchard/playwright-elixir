defmodule Playwright.Locator.EvaluateTest do
  use Playwright.TestCase, async: true

  alias Playwright.{Locator, Page, Runner.Channel}

  describe "Locator.evaluate/4" do
    test "retrieves a matching node", %{page: page} do
      locator = Page.locator(page, ".tweet .like")

      page
      |> Page.set_content("""
        <html>
        <body>
          <div class="tweet">
            <div class="like">100</div>
            <div class="retweets">10</div>
          </div>
        </body>
        </html>
      """)

      assert {:ok, "100"} = Locator.evaluate(locator, "node => node.innerText")
    end

    test "accepts `param: arg` for expression evaluation", %{page: page} do
      locator = Page.locator(page, ".counter")

      page
      |> Page.set_content("""
        <html>
        <body>
          <div class="counter">100</div>
        </body>
        </html>
      """)

      assert {:ok, 42} = Locator.evaluate(locator, "(node, number) => parseInt(node.innerText) - number", 58)
    end

    test "accepts `option: timeout` for expression evaluation", %{page: page} do
      locator = Page.locator(page, ".missing")
      options = %{timeout: 500}
      errored = {:error, %Channel.Error{message: "Timeout 500ms exceeded."}}

      page
      |> Page.set_content("""
        <html>
        <body>
          <div class="counter">100</div>
        </body>
        </html>
      """)

      assert ^errored = Locator.evaluate(locator, "(node, arg) => arg", "a", options)
    end

    test "accepts `option: timeout` without a `param: arg`", %{page: page} do
      locator = Page.locator(page, ".missing")
      options = %{timeout: 500}
      errored = {:error, %Channel.Error{message: "Timeout 500ms exceeded."}}

      page
      |> Page.set_content("""
        <html>
        <body>
          <div class="counter">100</div>
        </body>
        </html>
      """)

      assert ^errored = Locator.evaluate(locator, "(node) => node", options)
    end

    test "retrieves content from a subtree match", %{page: page} do
      locator = Page.locator(page, "#myId .a")

      page
      |> Page.set_content("""
        <div class="a">other content</div>
        <div id="myId">
          <div class="a">desired content</div>
        </div>
      """)

      assert {:ok, "desired content"} = Locator.evaluate(locator, "node => node.innerText")
    end
  end

  describe "Locator.evaluate_all/4" do
    test "retrieves a List of matching nodes", %{page: page} do
      locator = Page.locator(page, ".tweet .like")

      page
      |> Page.set_content("""
        <html>
        <body>
          <div class="tweet">
            <div class="like">100</div>
            <div class="like">10</div>
          </div>
        </body>
        </html>
      """)

      assert {:ok, ["100", "10"]} = Locator.evaluate_all(locator, "nodes => nodes.map(n => n.innerText)")
    end

    test "retrieves content from a subtree match", %{page: page} do
      locator = Page.locator(page, "#myId .a")

      page
      |> Page.set_content("""
        <div class="a">other content</div>
        <div id="myId">
          <div class="a">one</div>
          <div class="a">two</div>
        </div>
      """)

      assert {:ok, ["one", "two"]} = Locator.evaluate_all(locator, "nodes => nodes.map(n => n.innerText)")
    end

    test "does not throw in case of a selector 'miss'", %{page: page} do
      locator = Page.locator(page, "#myId .a")

      page
      |> Page.set_content("""
        <div class="a">other content</div>
        <div id="myId"></div>
      """)

      assert {:ok, 0} = Locator.evaluate_all(locator, "nodes => nodes.length")
    end
  end
end
