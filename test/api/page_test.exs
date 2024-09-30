defmodule Playwright.PageTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, ElementHandle, Frame, Locator, Page, Request, Response, Route}
  alias Playwright.API.Error
  alias Playwright.SDK.Channel
  alias Playwright.SDK.Channel.Event

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

  describe "Page.close/1" do
    @tag without: [:page]
    test "removes the Page", %{browser: browser} do
      page = Browser.new_page(browser)
      assert %Page{} = Channel.find(page.session, {:guid, page.guid})

      page |> Page.close()

      assert {:error, %Playwright.SDK.Error{message: "Timeout 100ms exceeded" <> _}} =
               Channel.find(page.session, {:guid, page.guid}, %{timeout: 100})
    end
  end

  describe "Page.click/3" do
    test "returns 'subject'", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")
      assert %Page{} = Page.click(page, "button")
    end

    test "with a button", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")
      Page.click(page, "button")
      assert Page.evaluate(page, "result") == "Clicked"
    end

    test "fires JS click handlers", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/button.html")

      page
      |> Page.click("css=button")

      assert Page.evaluate(page, "function () { return window['result']; }") == "Clicked"
    end
  end

  describe "Page.content/0" do
    test "retrieves the page content", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/dom.html")

      assert Page.content(page) =~
               ~r/<html>/
    end
  end

  describe "Page.dblclick/2, mimicking Python tests" do
    test "returns 'subject'", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")
      assert %Page{} = Page.dblclick(page, "button")
    end

    test "test_locators.py: `test_double_click_the_button`", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")

      Page.evaluate(page, """
        () => {
          window['double'] = false;
          const button = document.querySelector('button');
          button.addEventListener('dblclick', event => {
            window['double'] = true;
          });
        }
      """)

      page = Page.dblclick(page, "button")
      assert Page.evaluate(page, "window['double']") == true
      assert Page.evaluate(page, "window['result']") == "Clicked"
    end
  end

  describe "Page.drag_and_drop/4" do
    test "returns 'subject'", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/drag-n-drop.html")
      assert %Page{} = Page.drag_and_drop(page, "#source", "#target")
    end

    test "drags the source element to the target element", %{assets: assets, page: page} do
      page |> Page.goto(assets.prefix <> "/drag-n-drop.html")
      page |> Page.drag_and_drop("#source", "#target")

      assert Page.eval_on_selector(page, "#target", "target => target.contains(document.querySelector('#source'))")
    end
  end

  describe "Page.evaluate/2" do
    test "execute JS", %{page: page} do
      assert Page.evaluate(page, "function () { return 7 * 3; }") == 21
    end
  end

  describe "Page.get_by_text/3" do
    test "returns a locator that contains the given text", %{page: page} do
      Page.set_content(page, "<div><div>first</div><div>second</div><div>\nthird  </div></div>")
      assert page |> Page.get_by_text("first") |> Locator.count() == 1

      assert page |> Page.get_by_text("third") |> Locator.evaluate("e => e.outerHTML") == "<div>\nthird  </div>"
      Page.set_content(page, "<div><div> first </div><div>first</div></div>")

      assert page |> Page.get_by_text("first", %{exact: true}) |> Locator.first() |> Locator.evaluate("e => e.outerHTML") ==
               "<div> first </div>"

      Page.set_content(page, "<div><div> first and more </div><div>first</div></div>")

      assert page |> Page.get_by_text("first", %{exact: true}) |> Locator.first() |> Locator.evaluate("e => e.outerHTML") ==
               "<div>first</div>"
    end
  end

  describe "Page.goto/2" do
    test "works (and updates the page's URL)", %{assets: assets, page: page} do
      assert Page.url(page) == assets.blank

      Page.goto(page, assets.empty)
      assert Page.url(page) == assets.empty
    end

    test "works with anchor navigation", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)
      assert Page.url(page) == assets.empty

      Page.goto(page, assets.empty <> "#foo")
      assert Page.url(page) == assets.empty <> "#foo"

      Page.goto(page, assets.empty <> "#bar")
      assert Page.url(page) == assets.empty <> "#bar"
    end

    test "navigates to about:blank", %{assets: assets, page: page} do
      response = Page.goto(page, assets.blank)
      refute response
    end

    test "returns response when page changes its URL after load", %{assets: assets, page: page} do
      response = Page.goto(page, assets.prefix <> "/historyapi.html")
      assert response.status == 200
    end

    # !!! works w/out implementation
    test "navigates to empty page with domcontentloaded", %{assets: assets, page: page} do
      response = Page.goto(page, assets.empty, %{wait_until: "domcontentloaded"})
      assert response.status == 200
    end

    test "works when page calls history API in beforeunload", %{assets: assets, page: page} do
      Page.goto(page, assets.empty)

      Page.evaluate(page, """
      () => {
        window.addEventListener('beforeunload', () => history.replaceState(null, 'initial', window.location.href), false)
      }
      """)

      response = Page.goto(page, assets.prefix <> "/grid.html")
      assert response.status == 200
    end

    test "fails when navigating to bad URL", %{page: page} do
      error = %Error{
        type: "Error",
        message: "Protocol error (Page.navigate): Cannot navigate to invalid URL"
      }

      assert {:error, ^error} = Page.goto(page, "asdfasdf")
    end

    test "works when navigating to valid URL", %{assets: assets, page: page} do
      response = Page.goto(page, assets.empty)
      assert Response.ok(response)

      response = Page.goto(page, assets.empty)
      assert Response.ok(response)
    end
  end

  describe "Page.evaluate_handle/2" do
    alias Playwright.Page

    test "returns a JSHandle for the Window, given a function", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return window; }")
      assert is_struct(handle, Playwright.JSHandle)
      assert handle.preview == "Window"
    end

    test "returns a JSHandle for the Window, given an object reference", %{page: page} do
      handle = Page.evaluate_handle(page, "window")
      assert is_struct(handle, Playwright.JSHandle)
      assert handle.preview == "Window"
    end

    test "returns a handle that can be used as a later argument, as a handle to an object", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return navigator; }")
      assert Page.evaluate(page, "function(h) { return h.userAgent; }", handle) =~ "Mozilla"
    end

    test "returns a handle that can be used as a later argument, as a handle to a primitive type", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return 42; }")

      assert Page.evaluate(page, "function(h) { return Object.is(h, 42); }", handle) === true
      assert Page.evaluate(page, "function(n) { return n; }", handle) === 42
    end

    test "works with a handle that references an object", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return { x: 1, y: 'lala' }; }")
      assert Page.evaluate(page, "function(o) { return o; }", handle) == %{x: 1, y: "lala"}
    end

    test "works with a handle that references an object with nesting", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return { x: 1, y: { lala: 'lulu' } }; }")
      assert %Playwright.JSHandle{} = handle
      assert Page.evaluate(page, "function(o) { return o; }", handle) == %{x: 1, y: %{lala: "lulu"}}
    end

    test "works with a handle that references the window", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { return window; }")
      assert Page.evaluate(page, "function(w) { return w === window; }", handle) === true

      handle = Page.evaluate_handle(page, "window")
      result = Page.evaluate(page, "function(w) { return w === window; }", handle)
      assert result === true
    end

    test "works with multiple nested handles", %{page: page} do
      foo = Page.evaluate_handle(page, "function() { return { x: 1, y: 'foo' }; }")
      bar = Page.evaluate_handle(page, "function() { return 5; }")
      baz = Page.evaluate_handle(page, "function() { return ['baz']; }")
      bam = Page.evaluate_handle(page, "function() { return ['bam']; }")

      result =
        Page.evaluate(page, "function(x) { return JSON.stringify(x); }", %{
          a1: %{foo: foo},
          a2: %{bar: bar, arr: [%{baz: baz}, %{bam: bam}]}
        })

      assert result

      assert Jason.decode!(result) == %{
               "a1" => %{
                 "foo" => %{
                   "x" => 1,
                   "y" => "foo"
                 }
               },
               "a2" => %{
                 "bar" => 5,
                 "arr" => [%{"baz" => ["baz"]}, %{"bam" => ["bam"]}]
               }
             }
    end

    # Pending (page/page-evaluate-handle.spec.ts):
    # - it('should throw for circular objects', async ({page}) => {
    # - it('should accept same handle multiple times', async ({page}) => {
    # - it('should accept same nested object multiple times', async ({page}) => {
    # - it('should accept object handle to unserializable value', async ({page}) => {
    # - it('should pass configurable args', async ({page}) => {

    test "...primitive write/read", %{page: page} do
      handle = Page.evaluate_handle(page, "function() { window['LALA'] = 'LULU'; return window; }")
      result = Page.evaluate(page, "function(h) { return h['LALA']; }", handle)
      assert result == "LULU"
    end
  end

  describe "Page.expect_event/3 without a 'trigger" do
    test "w/ an event", %{assets: assets, page: page} do
      url = assets.empty

      Task.start(fn -> Page.goto(page, url) end)
      %Event{params: params} = Page.expect_event(page, :request_finished)

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a (truthy) predicate", %{assets: assets, page: page} do
      url = assets.empty

      Task.start(fn -> Page.goto(page, url) end)

      %Event{params: params} =
        Page.expect_event(page, :request_finished, %{
          predicate: fn owner, e ->
            %BrowserContext{} = owner
            %Event{} = e
            true
          end
        })

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a timeout", %{page: page} do
      {:error, %Playwright.SDK.Error{message: message}} =
        Page.expect_event(page, :request_finished, %{
          timeout: 500
        })

      assert "Timeout 500ms exceeded" <> _ = message
    end

    test "w/ an event, a (truthy) predicate, and a timeout", %{assets: assets, page: page} do
      Task.start(fn -> Page.goto(page, assets.empty) end)

      event =
        Page.expect_event(page, :request_finished, %{
          predicate: fn _, _ ->
            true
          end,
          timeout: 500
        })

      assert event.type == :request_finished
    end

    test "w/ an event, a (falsy) predicate, and (incidentally) a timeout", %{assets: assets, page: page} do
      Task.start(fn -> Page.goto(page, assets.empty) end)

      {:error, %Playwright.SDK.Error{message: message}} =
        Page.expect_event(page, :request_finished, %{
          predicate: fn _, _ ->
            false
          end,
          timeout: 500
        })

      assert "Timeout 500ms exceeded" <> _ = message
    end
  end

  describe "Page.expect_event/3 with a 'trigger" do
    test "w/ an event and a trigger", %{assets: assets, page: page} do
      url = assets.empty

      %Event{params: params} =
        Page.expect_event(page, :request_finished, fn ->
          Page.goto(page, url)
        end)

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a (truthy) predicate", %{assets: assets, page: page} do
      url = assets.empty

      %Event{params: params} =
        Page.expect_event(
          page,
          :request_finished,
          %{
            predicate: fn _, _ -> true end
          },
          fn ->
            Page.goto(page, url)
          end
        )

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a (falsy) predicate", %{assets: assets, page: page} do
      {:error, %Playwright.SDK.Error{message: message}} =
        Page.expect_event(
          page,
          :request_finished,
          %{
            predicate: fn _, _ ->
              false
            end,
            timeout: 500
          },
          fn ->
            Page.goto(page, assets.empty)
          end
        )

      assert "Timeout 500ms exceeded" <> _ = message
    end

    test "w/ an event and a timeout", %{assets: assets, page: page} do
      %Event{params: params} =
        Page.expect_event(
          page,
          :request_finished,
          %{
            timeout: 500
          },
          fn ->
            Page.goto(page, assets.empty)
          end
        )

      assert Response.ok(params.response)
    end
  end

  describe "Page.expose_binding/4" do
    test "returns 'subject'", %{page: page} do
      assert %Page{} = Page.expose_binding(page, "fn", fn -> nil end)
    end

    test "binds a local function", %{page: page} do
      pid = self()

      handler = fn source, [a, b] ->
        send(pid, source)
        a + b
      end

      Page.expose_binding(page, "add", handler)
      assert Page.evaluate(page, "add(5, 6)") == 11
      assert_received(%{context: "TBD", frame: %Frame{}, page: "TBD"})
    end
  end

  describe "Page.expose_function/3" do
    test "returns 'subject'", %{page: page} do
      assert %Page{} = Page.expose_function(page, "fn", fn -> nil end)
    end

    test "binds a local function", %{page: page} do
      handler = fn [a, b] ->
        a * b
      end

      Page.expose_function(page, "compute", handler)
      assert Page.evaluate(page, "compute(9, 4)") == 36
    end

    # test_expose_function_should_throw_exception_in_page_context
    # test_expose_function_should_be_callable_from_inside_add_init_script
    # test_expose_function_should_survive_navigation
    # test_expose_function_should_await_returned_promise
    # test_expose_function_should_work_on_frames
    # test_expose_function_should_work_on_frames_before_navigation
    # test_expose_function_should_work_after_cross_origin_navigation
    # test_expose_function_should_work_with_complex_objects
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

      assert(
        {:error, %Playwright.API.Error{message: "Timeout 500ms exceeded."}} =
          Page.get_attribute(page, "glorp", "foo", %{timeout: 500})
      )
    end
  end

  describe "Page.goto/3" do
    test "on success, returns a Response", %{assets: assets, page: page} do
      assert %Response{} = Page.goto(page, assets.prefix <> "/empty.html")
    end
  end

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
      test_pid = self()
      guid = page.guid

      Page.on(page, :close, fn event ->
        send(test_pid, event)
      end)

      Page.close(page)
      assert_received(%Event{params: nil, target: %Page{guid: ^guid, is_closed: true}, type: :close})
    end

    @tag exclude: [:page]
    test "on 'close' (string)", %{browser: browser} do
      page = Browser.new_page(browser)
      test_pid = self()
      guid = page.guid

      Page.on(page, "close", fn event ->
        assert Page.is_closed(event.target)
        send(test_pid, event)
      end)

      Page.close(page)
      assert_received(%Event{params: nil, target: %Page{guid: ^guid, is_closed: true}, type: :close})
    end

    # NOTE: this is really about *any* `on` event handling
    @tag exclude: [:page]
    test "on 'close' of one Page does not affect another", %{browser: browser} do
      test_pid = self()

      %{guid: guid_one} = page_one = Browser.new_page(browser)
      %{guid: guid_two} = page_two = Browser.new_page(browser)

      Page.on(page_one, "close", fn %{target: target} ->
        send(test_pid, target.guid)
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

      Page.evaluate(page, "function () { console.info('info!'); }")
      Page.evaluate(page, "console.error('error!')")

      assert_received(%Event{params: %{text: "info!", type: "info"}, type: :console})
      assert_received(%Event{params: %{text: "error!", type: "error"}, type: :console})
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

    # network events...
    test "events are fired in the proper order", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, :request, fn %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.on(page, :response, fn %{params: %{response: response}} ->
        send(pid, {:response, response.url})
      end)

      Page.on(page, :request_finished, fn %{params: %{request: request}} ->
        send(pid, {:finished, request.url})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, ^url})
      assert_next_receive({:response, ^url})
      assert_next_receive({:finished, ^url})
    end

    test "request/response event info includes :page", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, :request, fn %{params: %{page: page}} ->
        send(pid, {:request, page})
      end)

      Page.on(page, :response, fn %{params: %{page: page}} ->
        send(pid, {:response, page})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, %Page{}})
      assert_next_receive({:response, %Page{}})
    end
  end

  describe "Page.press/4" do
    test "triggers a key press on the focused element", %{assets: assets, page: page} do
      page
      |> Page.goto(assets.prefix <> "/input/textarea.html")

      page
      |> Page.press("textarea", "A")

      assert Page.evaluate(page, "function () { return document.querySelector('textarea').value; }") == "A"
    end
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

  describe "Page.screenshot/2" do
    # NOTE: in addition to the explicit assertions made by these tests, we're also
    # demonstrating a couple other capabilities/quirks:
    #
    # - Given the frame data size for a screenshot is (almost certainly) larger
    #   than 32K bytes, these test cover handling of multi-message frames.
    # - The fact that we do not reassign `page` after the `Page.goto` calls in
    #   these tests shows that there is state managed by the Playwright browser
    #   server (in the form of an open web page) that can be addressed by way
    #   of the static `Page.guid` that we hold in local state. Whether or not that
    #   is a good idea is left to the imagination of the consumer.
    test "caputures a screenshot, returning the base64 encoded binary", %{page: page} do
      case Page.goto(page, "https://playwright.dev", %{timeout: 5000}) do
        {:error, error} ->
          Logger.warning("Unabled to reach 'https://playwright.dev' for screenshot test: #{inspect(error)}")

        _ ->
          max_frame_size = 32_768
          raw = Page.screenshot(page, %{full_page: true, type: "png"})
          assert byte_size(raw) > max_frame_size
      end
    end

    test "caputures a screenshot, optionally writing the result to local disk", %{page: page} do
      slug = DateTime.utc_now() |> DateTime.to_unix()
      path = "screenshot-#{slug}.png"

      refute(File.exists?(path))

      case Page.goto(page, "https://playwright.dev", %{timeout: 5000}) do
        {:error, error} ->
          Logger.warning("Unabled to reach 'https://playwright.dev' for screenshot test: #{inspect(error)}")

        _ ->
          Page.screenshot(page, %{
            full_page: true,
            path: path
          })

          assert(File.exists?(path))
          File.rm!(path)
      end
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

      assert {:error, %Playwright.API.Error{message: "Timeout 500ms exceeded."}} =
               Page.select_option(page, "select", %{value: "green", label: "Brown"}, %{timeout: 500})
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

  describe "Page.set_content/2" do
    test "sets content", %{page: page} do
      page
      |> Page.set_content("<div id='content'>text</div>")

      assert Page.text_content(page, "div#content") == "text"
    end
  end

  describe "Page.text_content/2" do
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

# *.check/*
# - test_check_the_box(page):
# - test_not_check_the_checked_box(page):
# - test_uncheck_the_box(page):
# - test_not_uncheck_the_unchecked_box(page):
# - test_check_the_box_by_label(page):
# - test_check_the_box_outside_label(page):
# - test_check_the_box_inside_label_without_id(page):
# - test_check_radio(page):
# - test_check_the_box_by_aria_role(page):

# *.click/*
# - async def test_click_the_button(page, server):
# - async def test_click_svg(page, server):
# - async def test_click_the_button_if_window_node_is_removed(page, server):
# - async def test_click_on_a_span_with_an_inline_element_inside(page, server):
# - async def test_click_not_throw_when_page_closes(browser, server):
# - async def test_click_the_button_after_navigation(page, server):
# - async def test_click_the_button_after_a_cross_origin_navigation_(page, server):
# - async def test_click_with_disabled_javascript(browser, server):
# - async def test_click_when_one_of_inline_box_children_is_outside_of_viewport(
# - async def test_select_the_text_by_triple_clicking(page, server):
# - async def test_click_offscreen_buttons(page, server):
# - async def test_waitFor_visible_when_already_visible(page, server):
# - async def test_wait_with_force(page, server):
# - async def test_wait_for_display_none_to_be_gone(page, server):
# - async def test_wait_for_visibility_hidden_to_be_gone(page, server):
# - async def test_timeout_waiting_for_display_none_to_be_gone(page, server):
# - async def test_timeout_waiting_for_visbility_hidden_to_be_gone(page, server):
# - async def test_waitFor_visible_when_parent_is_hidden(page, server):
# - async def test_click_wrapped_links(page, server):
# - async def test_click_on_checkbox_input_and_toggle(page, server):
# - async def test_click_on_checkbox_label_and_toggle(page, server):
# - async def test_not_hang_with_touch_enabled_viewports(playwright, server, browser):
# - async def test_scroll_and_click_the_button(page, server):
# - async def test_double_click_the_button(page, server):
# - async def test_click_a_partially_obscured_button(page, server):
# - async def test_click_a_rotated_button(page, server):
# - async def test_fire_contextmenu_event_on_right_click(page, server):
# - async def test_click_links_which_cause_navigation(page, server):
# - async def test_click_the_button_with_device_scale_factor_set(browser, server, utils):
# - async def test_click_the_button_with_px_border_with_offset(page, server, is_webkit):
# - async def test_click_the_button_with_em_border_with_offset(page, server, is_webkit):
# - async def test_click_a_very_large_button_with_offset(page, server, is_webkit):
# - async def test_click_a_button_in_scrolling_container_with_offset(
# - async def test_click_the_button_with_offset_with_page_scale(
# - async def test_wait_for_stable_position(page, server):
# - async def test_timeout_waiting_for_stable_position(page, server):
# - async def test_wait_for_becoming_hit_target(page, server):
# - async def test_timeout_waiting_for_hit_target(page, server):
# - async def test_fail_when_obscured_and_not_waiting_for_hit_target(page, server):
# - async def test_wait_for_button_to_be_enabled(page, server):
# - async def test_timeout_waiting_for_button_to_be_enabled(page, server):
# - async def test_wait_for_input_to_be_enabled(page, server):
# - async def test_wait_for_select_to_be_enabled(page, server):
# - async def test_click_disabled_div(page, server):
# - async def test_climb_dom_for_inner_label_with_pointer_events_none(page, server):
# - async def test_climb_up_to_role_button(page, server):
# - async def test_wait_for_BUTTON_to_be_clickable_when_it_has_pointer_events_none(
# - async def test_wait_for_LABEL_to_be_clickable_when_it_has_pointer_events_none(
# - async def test_update_modifiers_correctly(page, server):
# - async def test_click_an_offscreen_element_when_scroll_behavior_is_smooth(page):
# - async def test_report_nice_error_when_element_is_detached_and_force_clicked(
# - async def test_fail_when_element_detaches_after_animation(page, server):
# - async def test_retry_when_element_detaches_after_animation(page, server):
# - async def test_retry_when_element_is_animating_from_outside_the_viewport(page, server):
# - async def test_fail_when_element_is_animating_from_outside_the_viewport_with_force(
# - async def test_not_retarget_when_element_changes_on_hover(page, server):
# - async def test_not_retarget_when_element_is_recycled_on_hover(page, server):
# - async def test_click_the_button_when_window_inner_width_is_corrupted(page, server):
# - async def test_timeout_when_click_opens_alert(page, server):
# - async def test_check_the_box(page):
# - async def test_not_check_the_checked_box(page):
# - async def test_uncheck_the_box(page):
# - async def test_not_uncheck_the_unchecked_box(page):
# - async def test_check_the_box_by_label(page):
# - async def test_check_the_box_outside_label(page):
# - async def test_check_the_box_inside_label_without_id(page):
# - async def test_check_radio(page):
# - async def test_check_the_box_by_aria_role(page):
