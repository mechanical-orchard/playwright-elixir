defmodule Playwright.PageTest do
  use ExUnit.Case
  use PlaywrightTest.Case
  require Logger

  describe "Page" do
    test ".query_selector/2", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/dom.html")

      page
      |> Page.query_selector("css=#outer")
      |> assert()

      page
      |> Page.query_selector("css=#non-existent")
      |> refute()

      Page.close(page)
    end

    test ".query_selector_all/2", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/dom.html")

      elements = Page.query_selector_all(page, "css=div")
      assert length(elements) > 1

      elements = Page.query_selector_all(page, "css=non-existent")
      assert length(elements) == 0

      Page.close(page)
    end

    test ".close/1", %{browser: browser, connection: connection} do
      page =
        browser
        |> Browser.new_page()

      Playwright.Client.Connection.has(connection, page.guid)
      |> assert()

      page |> Page.close()

      Playwright.Client.Connection.has(connection, page.guid)
      |> refute()
    end

    test ".click/2", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/input/button.html")
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

    test ".fill/3", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/input/textarea.html")
        |> Page.fill("textarea", "some value")

      value = Page.evaluate(page, "function () { return window['result']; }")
      assert value == "some value"

      Page.close(page)
    end

    test ".press/2", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/input/textarea.html")
        |> Page.press("textarea", "A")

      value = Page.evaluate(page, "function () { return document.querySelector('textarea').value; }")
      assert value == "A"

      Page.close(page)
    end

    test ".text_content/2", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/dom.html")

      assert Page.text_content(page, "div#inner") == "Text,\nmore text"

      Page.close(page)
    end

    test ".title/1", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/title.html")

      text = page |> Page.title()
      assert text == "Woof-Woof"

      Page.close(page)
    end
  end
end
