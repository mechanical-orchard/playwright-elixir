defmodule Test.Features.PageTest do
  use Playwright.TestCase, async: true
  alias Playwright.Runner.Connection

  describe "Page" do
    test ".query_selector/2", %{assets: assets, connection: connection, page: page} do
      Playwright.Page.goto(page, assets.prefix <> "/dom.html")

      assert %Playwright.ElementHandle{type: "ElementHandle", connection: ^connection, guid: guid} =
               page |> Playwright.Page.query_selector("css=#outer")

      assert guid != nil

      page
      |> Playwright.Page.query_selector("css=#non-existent")
      |> refute()
    end

    test "query_selector!/2", %{assets: assets, page: page} do
      Playwright.Page.goto(page, assets.prefix <> "/dom.html")

      assert_raise RuntimeError, "No element found for selector: #non-existent", fn ->
        page |> Playwright.Page.query_selector!("#non-existent")
      end
    end

    test ".query_selector_all/2", %{assets: assets, connection: connection, page: page} do
      Playwright.Page.goto(page, assets.prefix <> "/dom.html")

      [outer, inner] = Playwright.Page.query_selector_all(page, "css=div")

      assert %Playwright.ElementHandle{
               type: "ElementHandle",
               connection: ^connection,
               guid: outer_guid,
               preview: outer_preview
             } = outer

      assert %Playwright.ElementHandle{
               type: "ElementHandle",
               connection: ^connection,
               guid: inner_guid,
               preview: inner_preview
             } = inner

      assert outer_guid != nil
      assert inner_guid != nil
      assert outer_preview != "JSHandle@node"
      assert inner_preview != "JSHandle@node"
      assert Playwright.ElementHandle.text_content(outer) == "Text,\nmore text"

      elements = Playwright.Page.query_selector_all(page, "css=non-existent")
      assert elements == []
    end

    @tag without: [:page]
    test ".close/1", %{browser: browser, connection: connection} do
      page = Playwright.Browser.new_page(browser)

      Connection.get(connection, %{guid: page.guid}, nil)
      |> assert()

      page |> Playwright.Page.close()

      Connection.get(connection, %{guid: page.guid}, nil)
      |> refute()
    end

    test ".click/2", %{assets: assets, page: page} do
      page
      |> Playwright.Page.goto(assets.prefix <> "/input/button.html")

      page
      |> Playwright.Page.click("css=button")

      result = Playwright.Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"
    end

    test ".evaluate/2", %{page: page} do
      value = Playwright.Page.evaluate(page, "function () { return 7 * 3; }")
      assert value == 21
    end

    test ".fill/3", %{assets: assets, page: page} do
      page
      |> Playwright.Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Playwright.Page.fill("textarea", "some value")

      value = Playwright.Page.evaluate(page, "function () { return window['result']; }")
      assert value == "some value"
    end

    test ".get_attribute/3", %{assets: assets, page: page} do
      Playwright.Page.goto(page, assets.prefix <> "/dom.html")

      assert page |> Playwright.Page.get_attribute("div#outer", "name") == "value"
      assert page |> Playwright.Page.get_attribute("div#outer", "foo") == nil

      assert_raise RuntimeError, "No element found for selector: glorp", fn ->
        page |> Playwright.Page.get_attribute("glorp", "foo")
      end
    end

    test "goto/2 fails if the url is a relative URL", %{page: page} do
      assert_raise RuntimeError, ~s|Expected an absolute URL, got: "/relative/path"|, fn ->
        Playwright.Page.goto(page, "/relative/path")
      end
    end

    test ".press/2", %{assets: assets, page: page} do
      page
      |> Playwright.Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Playwright.Page.press("textarea", "A")

      value = Playwright.Page.evaluate(page, "function () { return document.querySelector('textarea').value; }")
      assert value == "A"
    end

    test ".set_content/2", %{page: page} do
      page
      |> Playwright.Page.set_content("<div id='content'>text</div>")

      assert Playwright.Page.text_content(page, "div#content") == "text"
    end

    test ".text_content/2", %{assets: assets, page: page} do
      page
      |> Playwright.Page.goto(assets.prefix <> "/dom.html")

      assert Playwright.Page.text_content(page, "div#inner") == "Text,\nmore text"
    end

    test ".title/1", %{assets: assets, page: page} do
      page
      |> Playwright.Page.goto(assets.prefix <> "/title.html")

      text = page |> Playwright.Page.title()
      assert text == "Woof-Woof"
    end

    test ".wait_for_selector/2", %{page: page} do
      page
      |> Playwright.Page.set_content("<div id='outer'></div>")

      Task.start(fn ->
        :timer.sleep(100)

        Playwright.Page.evaluate(
          page,
          "function () { var div = document.querySelector('div#outer'); div.innerHTML = '<span class=\"inner\">target</span>'; }"
        )
      end)

      Playwright.Page.wait_for_selector(page, "span.inner", %{state: "attached"})
      assert Playwright.Page.text_content(page, "span.inner") == "target"
    end
  end
end
