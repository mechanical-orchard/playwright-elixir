defmodule Playwright.PageTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, ElementHandle, Frame, Page, Request, Response, Route}
  alias Playwright.SDK.Channel.{Error, Event}
  alias Playwright.SDK.Channel

  describe "Page.hover/2" do
    test "triggers hover state", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/scrollable.html")
      page |> Page.hover("#button-6")

      assert Page.evaluate(page, "document.querySelector('button:hover').id") == "button-6"
    end
  end

  describe "Page.on/3" do
    @tag exclude: [:page]
    test "on :close (atom)", %{browser: browser} do
      page = Browser.new_page(browser)
      this = self()
      guid = page.guid

      Page.on(page, :close, fn event ->
        send(this, event)
      end)

      Page.close(page)
      assert_received(%Event{params: nil, target: %Page{guid: ^guid, is_closed: true}, type: :close})
    end

    @tag exclude: [:page]
    test "on 'close' (string)", %{browser: browser} do
      page = Browser.new_page(browser)
      this = self()
      guid = page.guid

      Page.on(page, "close", fn event ->
        assert Page.is_closed(event.target)
        send(this, event)
      end)

      Page.close(page)
      assert_received(%Event{params: nil, target: %Page{guid: ^guid, is_closed: true}, type: :close})
    end

    # NOTE: this is really about *any* `on` event handling
    @tag exclude: [:page]
    test "on 'close' of one Page does not affect another", %{browser: browser} do
      this = self()

      %{guid: guid_one} = page_one = Browser.new_page(browser)
      %{guid: guid_two} = page_two = Browser.new_page(browser)

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

      assert_received(%Event{params: %{message: %{message_text: "lala!", message_type: "info"}}, type: :console})
      assert_received(%Event{params: %{message: %{message_text: "lulu!", message_type: "error"}}, type: :console})
    end
  end

  test "on 'request' fires for navigation requests", %{assets: assets, page: page} do
    pid = self()
    url = assets.empty

    Page.on(page, "request", fn %{params: %{request: request}} ->
      send(pid, {:request, request.url})
    end)

    Page.goto(page, url)
    assert_next_receive({:request, ^url})
  end

  test "on 'reqeust' accepts a callback", %{assets: assets, page: page} do
    pid = self()
    url = assets.empty

    fun = fn event ->
      send(pid, event)
    end

    Page.on(page, "request", fun)
    Page.goto(page, url)

    assert_next_receive(%Event{type: :request})
  end

  test "on 'request' fires for iframes", %{assets: assets, page: page} do
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

  test "on 'request' fires for fetches", %{assets: assets, page: page} do
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

  describe "Page.route/3" do
    test "intercepts requests", %{assets: assets, page: page} do
      pid = self()

      Page.route(page, "**/empty.html", fn route, request ->
        assert route.request.guid == request.guid
        assert String.contains?(request.url, "empty.html")
        assert request.method == "GET"
        assert request.post_data == nil
        assert request.is_navigation_request == true
        assert request.resource_type == "document"
        assert Request.get_header(request, "user-agent")

        frame = Request.frame(request)
        assert frame == Page.main_frame(page)
        assert Frame.url(frame) == "about:blank"

        Route.continue(route)
        send(pid, :intercepted)
      end)

      response = Page.goto(page, assets.prefix <> "/empty.html")
      assert Response.ok(response)

      assert_received(:intercepted)
    end
  end

  describe "Page.select_option/4" do
    test "with a single option", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", "blue")

      assert Page.evaluate(page, "() => window['result'].onChange") == ["blue"]
      assert Page.evaluate(page, "() => window['result'].onInput") == ["blue"]
    end

    test "with a single option by :value", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{value: "blue"})

      assert Page.evaluate(page, "() => window['result'].onChange") == ["blue"]
      assert Page.evaluate(page, "() => window['result'].onInput") == ["blue"]
    end

    test "with a single option by :label", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{label: "Indigo"})

      assert Page.evaluate(page, "() => window['result'].onChange") == ["indigo"]
      assert Page.evaluate(page, "() => window['result'].onInput") == ["indigo"]
    end

    test "with a single option by ElementHandle", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", Page.query_selector(page, "[id=whiteOption]"))

      assert Page.evaluate(page, "() => window['result'].onChange") == ["white"]
      assert Page.evaluate(page, "() => window['result'].onInput") == ["white"]
    end

    test "with a single option by :index", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{index: 2})

      assert Page.evaluate(page, "() => window['result'].onChange") == ["brown"]
      assert Page.evaluate(page, "() => window['result'].onInput") == ["brown"]
    end

    test "with a single option by multiple attributes", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", %{value: "green", label: "Green"})

      assert Page.evaluate(page, "() => window['result'].onChange") == ["green"]
      assert Page.evaluate(page, "() => window['result'].onInput") == ["green"]
    end

    test "with a single option given mismatched attributes, returns a timeout", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")

      assert {:error, %Error{message: "Timeout 200ms exceeded."}} =
               Page.select_option(page, "select", %{value: "green", label: "Brown"}, %{timeout: 200})
    end

    test "with multiple options and a single-option select, selects the first", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/input/select.html")
      page |> Page.select_option("select", ["blue", "green", "red"])

      assert Page.evaluate(page, "() => window['result'].onChange") == ["blue"]
      assert Page.evaluate(page, "() => window['result'].onInput") == ["blue"]
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

  describe "Page.query_selector/2" do
    test "returns an ElementHandle or nil", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert %ElementHandle{guid: guid} = page |> Page.query_selector("css=#outer")

      assert guid != nil
      assert page |> Page.query_selector("css=#non-existent") === nil
    end
  end

  describe "Page.query_selector_all/2" do
    test "returns a list of ElementHandles", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      [outer, inner] = Page.query_selector_all(page, "css=div")

      assert %ElementHandle{
               guid: outer_guid,
               preview: outer_preview
             } = outer

      assert %ElementHandle{
               guid: inner_guid,
               preview: inner_preview
             } = inner

      assert outer_guid != nil
      assert inner_guid != nil
      assert outer_preview == "JSHandle@<div id=\"outer\" name=\"value\">…</div>"
      assert inner_preview == "JSHandle@<div id=\"inner\">Text,↵more text</div>"
      assert ElementHandle.text_content(outer) == "Text,\nmore text"

      elements = Page.query_selector_all(page, "css=non-existent")
      assert elements == []
    end
  end

  describe "Page.close/1" do
    @tag without: [:page]
    test "removes the Page", %{browser: browser} do
      page = Browser.new_page(browser)
      assert %Page{} = Channel.find(page.session, {:guid, page.guid})

      page |> Page.close()

      assert {:error, %Error{message: "Timeout 100ms exceeded."}} =
               Channel.find(page.session, {:guid, page.guid}, %{timeout: 100})
    end
  end

  describe "Page.click/2" do
    test "fires JS click handlers", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/button.html")

      page
      |> Page.click("css=button")

      assert Page.evaluate(page, "function () { return window['result']; }") == "Clicked"
    end
  end

  describe "Page.evaluate/2" do
    test "execute JS", %{page: page} do
      assert Page.evaluate(page, "function () { return 7 * 3; }") == 21
    end
  end

  describe "Page.fill/3" do
    test "sets text content", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Page.fill("textarea", "some value")

      assert Page.evaluate(page, "function () { return window['result']; }") == "some value"
    end
  end

  describe "Page.get_attribute/3" do
    test "returns an element's attribute value or nil", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/dom.html")

      assert page |> Page.get_attribute("div#outer", "name") == "value"
      assert page |> Page.get_attribute("div#outer", "foo") == nil

      assert({:error, %Error{}} = Page.get_attribute(page, "glorp", "foo", %{timeout: 200}))
    end
  end

  describe "Page.press/s" do
    test "triggers a key press on the focused element", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Page.press("textarea", "A")

      assert Page.evaluate(page, "function () { return document.querySelector('textarea').value; }") == "A"
    end
  end

  describe "Page.set_content/2" do
    test "sets content", %{page: page} do
      page
      |> Page.set_content("<div id='content'>text</div>")

      assert Page.text_content(page, "div#content") == "text"
    end
  end

  describe "Page.test_content/2" do
    test "retrieves content", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/dom.html")

      assert Page.text_content(page, "div#inner") == "Text,\nmore text"
    end
  end

  describe "Page.title/1" do
    test "retrieves the title text", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/title.html")

      text = page |> Page.title()
      assert text == "Woof-Woof"
    end
  end

  describe "Page.wait_for_selector/3" do
    test "blocks until the selector matches", %{page: page} do
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
      assert Page.text_content(page, "span.inner") == "target"
    end

    test "takes an optional state on which to wait", %{page: page} do
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
  end
end
