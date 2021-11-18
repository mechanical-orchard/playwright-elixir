defmodule Playwright.PageTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, ElementHandle, Page}
  alias Playwright.Runner.Connection

  describe "Page" do
    test ".query_selector/2", %{assets: assets, connection: connection, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert {:ok, %ElementHandle{type: "ElementHandle", connection: ^connection, guid: guid}} =
               page |> Page.query_selector("css=#outer")

      assert guid != nil

      assert {:ok, nil} = page |> Page.query_selector("css=#non-existent")
    end

    test "query_selector!/2", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert_raise RuntimeError, "No element found for selector: #non-existent", fn ->
        page |> Page.query_selector!("#non-existent")
      end
    end

    test ".query_selector_all/2", %{assets: assets, connection: connection, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html", %{timeout: 5_000, wait_until: "domcontentloaded"})

      assert {:ok, [outer, inner]} = Page.query_selector_all(page, "css=div")

      assert %ElementHandle{
               type: "ElementHandle",
               connection: ^connection,
               guid: outer_guid,
               preview: outer_preview
             } = outer

      assert %ElementHandle{
               type: "ElementHandle",
               connection: ^connection,
               guid: inner_guid,
               preview: inner_preview
             } = inner

      assert outer_guid != nil
      assert inner_guid != nil
      assert outer_preview != "JSHandle@node"
      assert inner_preview != "JSHandle@node"
      assert ElementHandle.text_content(outer) == "Text,\nmore text"

      assert {:ok, []} = Page.query_selector_all(page, "css=non-existent")
    end

    @tag without: [:page]
    test ".close/1", %{browser: browser, connection: connection} do
      page = Browser.new_page(browser)

      Connection.get(connection, %{guid: page.guid}, nil)
      |> assert()

      page |> Page.close()

      Connection.get(connection, %{guid: page.guid}, nil)
      |> refute()
    end

    test ".click/2", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/button.html")

      page
      |> Page.click("css=button")

      result = Page.evaluate(page, "function () { return window['result']; }")
      assert result == "Clicked"
    end

    test ".evaluate/2", %{page: page} do
      value = Page.evaluate(page, "function () { return 7 * 3; }")
      assert value == 21
    end

    test ".fill/3", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Page.fill("textarea", "some value")

      value = Page.evaluate(page, "function () { return window['result']; }")
      assert value == "some value"
    end

    test ".get_attribute/3", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert page |> Page.get_attribute("div#outer", "name") == "value"
      assert page |> Page.get_attribute("div#outer", "foo") == nil

      assert_raise RuntimeError, "No element found for selector: glorp", fn ->
        page |> Page.get_attribute("glorp", "foo")
      end
    end

    test ".press/2", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Page.press("textarea", "A")

      value = Page.evaluate(page, "function () { return document.querySelector('textarea').value; }")
      assert value == "A"
    end

    test ".set_content/2", %{page: page} do
      page
      |> Page.set_content("<div id='content'>text</div>")

      assert Page.text_content(page, "div#content") == "text"
    end

    test ".text_content/2", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/dom.html")

      assert Page.text_content(page, "div#inner") == "Text,\nmore text"
    end

    test ".title/1", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/title.html")

      text = page |> Page.title()
      assert text == "Woof-Woof"
    end

    test ".wait_for_selector/2", %{page: page} do
      page
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
    end

    test ".cookies/1", %{assets: assets, page: page} do
      page
      |> Playwright.Page.goto(assets.extras <> "/cookiesapi.html")

      cookies = page |> Playwright.Page.cookies()

      assert cookies == [
               %{
                 name: "testcookie",
                 value: "crunchcrunch",
                 domain: "localhost",
                 expires: -1,
                 httpOnly: false,
                 path: "/",
                 sameSite: "Lax",
                 secure: false
               }
             ]
    end

    test ".add_cookies/2", %{assets: assets, page: page} do
      page
      |> Playwright.Page.add_cookies([
        %{
          name: "testcookie",
          value: "crunchcrunch",
          domain: "localhost",
          expires: -1,
          httpOnly: false,
          path: "/",
          sameSite: "Lax",
          secure: false
        }
      ])

      page
      |> Playwright.Page.goto(assets.prefix <> "/empty.html")

      cookies = page |> Playwright.Page.cookies()

      assert cookies == [
               %{
                 name: "testcookie",
                 value: "crunchcrunch",
                 domain: "localhost",
                 expires: -1,
                 httpOnly: false,
                 path: "/",
                 sameSite: "Lax",
                 secure: false
               }
             ]
    end
  end
end
