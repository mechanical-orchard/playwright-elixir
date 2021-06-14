defmodule Test.Features.PageTest do
  use Playwright.TestCase

  describe "Page" do
    test ".query_selector/2", %{assets: assets, browser: browser, connection: connection} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/dom.html")

      assert %Playwright.ElementHandle{type: "ElementHandle", connection: ^connection, guid: guid} =
               page |> Playwright.Page.query_selector("css=#outer")

      assert guid != nil

      page
      |> Playwright.Page.query_selector("css=#non-existent")
      |> refute()

      Playwright.Page.close(page)
    end

    test ".query_selector_all/2", %{assets: assets, browser: browser, connection: connection} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/dom.html")

      [outer_div, inner_div] = Playwright.Page.query_selector_all(page, "css=div")
      assert %Playwright.ElementHandle{type: "ElementHandle", connection: ^connection, guid: outer_div_guid} = outer_div
      assert %Playwright.ElementHandle{type: "ElementHandle", connection: ^connection, guid: inner_div_guid} = inner_div
      assert outer_div_guid != nil
      assert inner_div_guid != nil
      assert Playwright.ElementHandle.text_content(outer_div) == "Text,\nmore text"

      elements = Playwright.Page.query_selector_all(page, "css=non-existent")
      assert elements == []

      Playwright.Page.close(page)
    end

    test ".close/1", %{browser: browser, connection: connection} do
      page =
        browser
        |> Playwright.Browser.new_page()

      Playwright.Client.Connection.find(connection, %{guid: page.guid}, nil)
      |> assert()

      page |> Playwright.Page.close()

      Playwright.Client.Connection.find(connection, %{guid: page.guid}, nil)
      |> refute()
    end

    test ".click/2", %{assets: assets, browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/input/button.html")
        |> Playwright.Page.click("css=button")

      result = Playwright.Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"

      Playwright.Page.close(page)
    end

    test ".evaluate/2", %{browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()

      value = Playwright.Page.evaluate(page, "function () { return 7 * 3; }")
      assert value == 21

      Playwright.Page.close(page)
    end

    test ".fill/3", %{assets: assets, browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/input/textarea.html")
        |> Playwright.Page.fill("textarea", "some value")

      value = Playwright.Page.evaluate(page, "function () { return window['result']; }")
      assert value == "some value"

      Playwright.Page.close(page)
    end

    test ".press/2", %{assets: assets, browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/input/textarea.html")
        |> Playwright.Page.press("textarea", "A")

      value = Playwright.Page.evaluate(page, "function () { return document.querySelector('textarea').value; }")
      assert value == "A"

      Playwright.Page.close(page)
    end

    test ".set_content/2", %{browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.set_content("<div id='content'>text</div>")

      assert Playwright.Page.text_content(page, "div#content") == "text"

      Playwright.Page.close(page)
    end

    test ".text_content/2", %{assets: assets, browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/dom.html")

      assert Playwright.Page.text_content(page, "div#inner") == "Text,\nmore text"

      Playwright.Page.close(page)
    end

    test ".title/1", %{assets: assets, browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto(assets.prefix <> "/title.html")

      text = page |> Playwright.Page.title()
      assert text == "Woof-Woof"

      Playwright.Page.close(page)
    end

    test ".wait_for_selector/2", %{browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
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

      Playwright.Page.close(page)
    end
  end
end
