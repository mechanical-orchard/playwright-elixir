defmodule Test.Features.PageTest do
  use Playwright.TestCase

  describe "Page" do
    test ".query_selector/2", %{assets: assets, browser: browser, connection: connection} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/dom.html")

      assert %ElementHandle{type: "ElementHandle", connection: ^connection, guid: guid} =
               page |> Page.query_selector("css=#outer")

      assert guid != nil

      page
      |> Page.query_selector("css=#non-existent")
      |> refute()

      Page.close(page)
    end

    test ".query_selector_all/2", %{assets: assets, browser: browser, connection: connection} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/dom.html")

      [outer_div, inner_div] = Page.query_selector_all(page, "css=div")
      assert %ElementHandle{type: "ElementHandle", connection: ^connection, guid: outer_div_guid} = outer_div
      assert %ElementHandle{type: "ElementHandle", connection: ^connection, guid: inner_div_guid} = inner_div
      assert outer_div_guid != nil
      assert inner_div_guid != nil
      assert ElementHandle.text_content(outer_div) == "Text,\nmore text"

      elements = Page.query_selector_all(page, "css=non-existent")
      assert elements == []

      Page.close(page)
    end

    test ".close/1", %{browser: browser, connection: connection} do
      page =
        browser
        |> Browser.new_page()

      Playwright.Client.Connection.find(connection, %{guid: page.guid}, nil)
      |> assert()

      page |> Page.close()

      Playwright.Client.Connection.find(connection, %{guid: page.guid}, nil)
      |> refute()
    end

    test ".click/2", %{assets: assets, browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/input/button.html")
        |> Page.click("css=button")

      result = Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"

      Page.close(page)
    end

    test ".evaluate/2", %{browser: browser} do
      page =
        browser
        |> Browser.new_page()

      value = Page.evaluate(page, "function () { return 7 * 3; }")
      assert value == 21

      Page.close(page)
    end

    test ".fill/3", %{assets: assets, browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/input/textarea.html")
        |> Page.fill("textarea", "some value")

      value = Page.evaluate(page, "function () { return window['result']; }")
      assert value == "some value"

      Page.close(page)
    end

    test ".press/2", %{assets: assets, browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/input/textarea.html")
        |> Page.press("textarea", "A")

      value = Page.evaluate(page, "function () { return document.querySelector('textarea').value; }")
      assert value == "A"

      Page.close(page)
    end

    test ".set_content/2", %{browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.set_content("<div id='content'>text</div>")

      assert Page.text_content(page, "div#content") == "text"

      Page.close(page)
    end

    test ".text_content/2", %{assets: assets, browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/dom.html")

      assert Page.text_content(page, "div#inner") == "Text,\nmore text"

      Page.close(page)
    end

    test ".title/1", %{assets: assets, browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(assets.prefix <> "/title.html")

      text = page |> Page.title()
      assert text == "Woof-Woof"

      Page.close(page)
    end

    test ".wait_for_selector/2", %{browser: browser} do
      page =
        browser
        |> Browser.new_page()
        |> Page.set_content("<div id='outer'></div>")

      Task.start(fn ->
        :timer.sleep(100)

        Page.evaluate(
          page,
          "function () { var div = document.querySelector('div#outer'); div.innerHTML = '<span class=\"inner\">target</span>'; }"
        )
      end)

      Page.wait_for_selector(page, "span.inner", %{state: "attached"})
      assert Page.text_content(page, "span.inner") == "target"

      Page.close(page)
    end
  end
end
