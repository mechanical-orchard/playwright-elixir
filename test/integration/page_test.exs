defmodule Playwright.PageTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, ElementHandle, Page}
  alias Playwright.Runner.{Channel, Connection, EventInfo}

  describe "Page.hover/2" do
    test "triggers hover state", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/scrollable.html")
      page |> Page.hover("#button-6")

      assert {:ok, "button-6"} = Page.evaluate(page, "document.querySelector('button:hover').id")
    end
  end

  describe "Page.on/3" do
    @tag exclude: [:page]
    test "on :close (atom)", %{browser: browser} do
      {:ok, page} = Browser.new_page(browser)
      this = self()
      guid = page.guid

      Page.on(page, :close, fn event ->
        send(this, event)
      end)

      Page.close(page)
      assert_received(%EventInfo{params: %{}, target: %Page{guid: ^guid, is_closed: true}, type: :close})
    end

    @tag exclude: [:page]
    test "on 'close' (string)", %{browser: browser} do
      {:ok, page} = Browser.new_page(browser)
      this = self()
      guid = page.guid

      Page.on(page, "close", fn event ->
        assert Page.is_closed(event.target)
        send(this, event)
      end)

      Page.close(page)
      assert_received(%EventInfo{params: %{}, target: %Page{guid: ^guid, is_closed: true}, type: :close})
    end

    # NOTE: this is really about *any* `on` event handling
    @tag exclude: [:page]
    test "on 'close' of one Page does not affect another", %{browser: browser} do
      this = self()

      {:ok, %{guid: guid_one}} = page_one = Browser.new_page(browser)
      {:ok, %{guid: guid_two}} = page_two = Browser.new_page(browser)

      Page.on(page_one, "close", fn %{target: target} ->
        send(this, target.guid)
      end)

      Page.close(page_one)
      Page.close(page_two)

      assert_received(^guid_one)
      refute_received(^guid_two)
    end

    test "on 'console'", %{page: page} do
      test_pid = self()

      Page.on(page, "console", fn event ->
        send(test_pid, event)
      end)

      Page.evaluate(page, "function () { console.info('lala!'); }")
      Page.evaluate(page, "console.error('lulu!')")

      assert_received(%EventInfo{params: %{message: %{message_text: "lala!", message_type: "info"}}, type: :console})
      assert_received(%EventInfo{params: %{message: %{message_text: "lulu!", message_type: "error"}}, type: :console})
    end
  end

  describe "Page.on(_, event, _) for `request` event" do
    test "fires for navigation requests", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "request", fn %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, ^url})
    end

    test "accepts a callback", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      fun = fn event ->
        send(pid, event)
      end

      Page.on(page, "request", fun)
      Page.goto(page, url)

      assert_next_receive(%EventInfo{type: :request})
    end

    test "fires for iframes", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "request", fn %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.goto(page, url)
      attach_frame(page, "frame1", url)

      assert_next_receive({:request, ^url})
      assert_next_receive({:request, ^url})
    end

    test "fires for fetches", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "request", fn %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.goto(page, url)
      Page.evaluate(page, "() => { fetch('#{url}') }")

      assert_next_receive({:request, ^url})
      assert_next_receive({:request, ^url})
    end
  end

  describe "Page.select_option/4" do
    test "with a single option", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", "blue")

      assert {:ok, ["blue"]} = Page.evaluate(page, "() => window['result'].onChange")
      assert {:ok, ["blue"]} = Page.evaluate(page, "() => window['result'].onInput")
    end

    test "with a single option by :value", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{value: "blue"})

      assert {:ok, ["blue"]} = Page.evaluate(page, "() => window['result'].onChange")
      assert {:ok, ["blue"]} = Page.evaluate(page, "() => window['result'].onInput")
    end

    test "with a single option by :label", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{label: "Indigo"})

      assert {:ok, ["indigo"]} = Page.evaluate(page, "() => window['result'].onChange")
      assert {:ok, ["indigo"]} = Page.evaluate(page, "() => window['result'].onInput")
    end

    test "with a single option by ElementHandle", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", Page.query_selector!(page, "[id=whiteOption]"))

      assert {:ok, ["white"]} = Page.evaluate(page, "() => window['result'].onChange")
      assert {:ok, ["white"]} = Page.evaluate(page, "() => window['result'].onInput")
    end

    test "with a single option by :index", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{index: 2})

      assert {:ok, ["brown"]} = Page.evaluate(page, "() => window['result'].onChange")
      assert {:ok, ["brown"]} = Page.evaluate(page, "() => window['result'].onInput")
    end

    test "with a single option by multiple attributes", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{value: "green", label: "Green"})

      assert {:ok, ["green"]} = Page.evaluate(page, "() => window['result'].onChange")
      assert {:ok, ["green"]} = Page.evaluate(page, "() => window['result'].onInput")
    end

    test "with a single option given mismatched attributes, returns a timeout", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")

      assert {:error, %Channel.Error{message: "Timeout 200ms exceeded."}} =
               Page.select_option(page, "select", %{value: "green", label: "Brown"}, %{timeout: 200})
    end

    test "with multiple options and a single-option select, selects the first", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", ["blue", "green", "red"])

      assert {:ok, ["blue"]} = Page.evaluate(page, "() => window['result'].onChange")
      assert {:ok, ["blue"]} = Page.evaluate(page, "() => window['result'].onInput")
    end

    # test "does not throw when select causes navigation"
    # test "selects multiple options"
    # test "selects multiple options with attributes"
    # test "selects options with sibling label"
    # test "selects options with outer label"
    # test "respects event bubbling"
    # test "throws when element is not a <select>"
    # test "returns [] on no matched values"
    # test "returns an array of matched values"
    # test "returns an array of one element when multiple is not set"
    # test "returns [] on no values',async ({ page, server }) => {
    # test "does not allow nil items',async ({ page, server }) => {
    # test "unselects with nil',async ({ page, server }) => {
    # test "deselects all options when passed no values for a multiple select',async ({ page, server }) => {
    # test "deselects all options when passed no values for a select without multiple',async ({ page, server }) => {
    # test "throws if passed wrong types"
    # test "works when re-defining top-level Event class"
    # test "waits for option to be present',async ({ page, server }) => {
    # test "waits for option index to be present',async ({ page, server }) => {
    # test "waits for multiple options to be present',async ({ page, server }) => {
  end

  describe "more Page stuff..." do
    test ".query_selector/2", %{assets: assets, connection: connection, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert {:ok, %ElementHandle{type: "ElementHandle", connection: ^connection, guid: guid}} =
               page |> Page.query_selector("css=#outer")

      assert guid != {:ok, nil}
      assert page |> Page.query_selector("css=#non-existent") == {:ok, nil}
    end

    test "query_selector!/2", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert_raise RuntimeError, "No element found for selector: #non-existent", fn ->
        page |> Page.query_selector!("#non-existent")
      end
    end

    # NOTE: query_selector_all, and ElementHandles, are somewhat problematic.
    # Specifically, we don't always receive the `previewUpdated` event, which
    # results in a timeout, crashing everything.
    @tag :skip
    test ".query_selector_all/2", %{assets: assets, connection: connection, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      {:ok, [outer, inner]} = Page.query_selector_all(page, "css=div")

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
      assert outer_preview == "JSHandle@<div id=\"outer\" name=\"value\">…</div>"
      assert inner_preview == "JSHandle@<div id=\"inner\">Text,↵more text</div>"
      assert ElementHandle.text_content(outer) == {:ok, "Text,\nmore text"}

      elements = Page.query_selector_all(page, "css=non-existent")
      assert elements == {:ok, []}
    end

    @tag without: [:page]
    test ".close/1", %{browser: browser, connection: connection} do
      {:ok, page} = Browser.new_page(browser)

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
      assert result == {:ok, "Clicked"}
    end

    test ".evaluate/2", %{page: page} do
      value = Page.evaluate(page, "function () { return 7 * 3; }")
      assert value == {:ok, 21}
    end

    test ".fill/3", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Page.fill("textarea", "some value")

      value = Page.evaluate(page, "function () { return window['result']; }")
      assert value == {:ok, "some value"}
    end

    test ".get_attribute/3", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert page |> Page.get_attribute("div#outer", "name") == {:ok, "value"}
      assert page |> Page.get_attribute("div#outer", "foo") == {:ok, nil}

      assert({:error, %Channel.Error{}} = Page.get_attribute(page, "glorp", "foo", %{timeout: 200}))
    end

    test ".press/2", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Page.press("textarea", "A")

      value = Page.evaluate(page, "function () { return document.querySelector('textarea').value; }")
      assert value == {:ok, "A"}
    end

    test ".set_content/2", %{page: page} do
      page
      |> Page.set_content("<div id='content'>text</div>")

      assert Page.text_content(page, "div#content") == {:ok, "text"}
    end

    test ".text_content/2", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/dom.html")

      assert Page.text_content(page, "div#inner") == {:ok, "Text,\nmore text"}
    end

    test ".title/1", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/title.html")

      text = page |> Page.title()
      assert text == {:ok, "Woof-Woof"}
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

      Page.wait_for_selector(page, "span.inner")
      assert Page.text_content(page, "span.inner") == {:ok, "target"}
    end

    test ".wait_for_selector/3", %{page: page} do
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
      assert Page.text_content(page, "span.inner") == {:ok, "target"}
    end
  end
end
