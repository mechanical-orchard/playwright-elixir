defmodule Playwright.BrowserContextTest do
  use Playwright.TestCase, async: true
  alias Playwright.API.Error
  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.CDPSession
  alias Playwright.Frame
  alias Playwright.Page
  alias Playwright.Request
  alias Playwright.Response
  alias Playwright.Route

  describe "BrowserContext.add_cookies/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      cookies = [%{url: assets.empty, name: "password", value: "123456"}]
      assert %BrowserContext{} = BrowserContext.add_cookies(context, cookies)
    end

    test "on failure, returns `{:error, error}`", %{page: page} do
      context = Page.owned_context(page)
      assert {:error, %Error{}} = BrowserContext.add_cookies(context, [%{bogus: "cookie"}])
    end

    test "adds cookies, readable by Page", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      page |> Page.goto(assets.empty)

      context
      |> BrowserContext.add_cookies([
        %{url: assets.empty, name: "password", value: "123456"}
      ])

      assert Page.evaluate(page, "() => document.cookie") == "password=123456"
    end

    # test_should_roundtrip_cookie
    # test_should_send_cookie_header
    # test_should_isolate_cookies_in_browser_contexts
    # test_should_isolate_session_cookies
    # test_should_isolate_persistent_cookies
    # test_should_isolate_send_cookie_header
    # test_should_isolate_cookies_between_launches
    # test_should_set_multiple_cookies
    # test_should_have_expires_set_to_neg_1_for_session_cookies
    # test_should_set_cookie_with_reasonable_defaults
    # test_should_set_a_cookie_with_a_path
    # test_should_not_set_a_cookie_with_blank_page_url
    # test_should_not_set_a_cookie_on_a_data_url_page
    # test_should_default_to_setting_secure_cookie_for_https_websites
    # test_should_be_able_to_set_unsecure_cookie_for_http_website
    # test_should_set_a_cookie_on_a_different_domain
    # test_should_set_cookies_for_a_frame
    # test_should_not_block_third_party_cookies
  end

  describe "BrowserContext.add_cookies!/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      cookies = [%{url: assets.empty, name: "password", value: "123456"}]
      assert %BrowserContext{} = BrowserContext.add_cookies(context, cookies)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "cookies[0].name: expected string, got undefined", fn ->
        context = Page.owned_context(page)
        BrowserContext.add_cookies!(context, [%{bogus: "cookie"}])
      end
    end
  end

  describe "BrowserContext.add_init_script/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.add_init_script(context, "window.injected = 123")
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      context = Browser.new_context(browser)
      context = %{context | guid: "bogus"}
      assert {:error, %Error{}} = BrowserContext.add_cookies(context, [%{bogus: "cookie"}])
    end

    @tag exclude: [:page]
    test "combined with `Page.add_init_script/2`", %{browser: browser} do
      context = Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      BrowserContext.add_init_script(context, "window.temp = 123")
      page = Page.add_init_script(page, "window.injected = window.temp")
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end

    @tag exclude: [:page]
    test "providing `param: script` as a file path", %{browser: browser} do
      context = Browser.new_context(browser)
      fixture = "test/support/fixtures/injectedfile.js"
      page = BrowserContext.new_page(context)

      BrowserContext.add_init_script(context, %{path: fixture})
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end

    test "adding to the BrowserContext for an already created Page", %{page: page} do
      context = Page.owned_context(page)

      BrowserContext.add_init_script(context, "window.temp = 123")
      page = Page.add_init_script(page, "window.injected = window.temp")
      nil = Page.goto(page, "data:text/html,<script>window.result = window.injected</script>")

      assert Page.evaluate(page, "window.result") == 123
    end
  end

  describe "BrowserContext.add_init_script!/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{browser: browser} do
      context = Browser.new_context!(browser)
      assert %BrowserContext{} = BrowserContext.add_init_script!(context, "window.injected = 123")
    end

    test "on failure, raises `RuntimeError`", %{browser: browser} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Browser.new_context(browser)
        context = %{context | guid: "bogus"}
        BrowserContext.add_init_script!(context, "window.injected = 123")
      end
    end
  end

  describe "BrowserContext.background_pages/1" do
  end

  describe "BrowserContext.browser/1" do
    test "returns the Browser", %{browser: browser, page: page} do
      context = Page.context(page)
      assert BrowserContext.browser(context) == browser
    end
  end

  describe "BrowserContext.clear_cookies/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.owned_context(page)
      assert %BrowserContext{} = BrowserContext.clear_cookies(context)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      context = Browser.new_context(browser)
      context = %{context | guid: "bogus"}
      assert {:error, %Error{}} = BrowserContext.clear_cookies(context)
    end

    test "clears cookies for the context", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.add_cookies(context, [%{url: assets.empty, name: "cookie1", value: "one"}])
      assert Page.evaluate(page, "document.cookie") == "cookie1=one"

      BrowserContext.clear_cookies(context)
      assert BrowserContext.cookies(context) == []

      Page.reload(page)
      assert Page.evaluate(page, "document.cookie") == ""
    end

    # test_should_isolate_cookies_when_clearing
  end

  describe "BrowserContext.clear_cookies!/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.owned_context(page)
      assert %BrowserContext{} = BrowserContext.clear_cookies!(context)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.owned_context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.clear_cookies!(context)
      end
    end
  end

  describe "BrowserContext.clear_permissions/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.clear_permissions(context)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      context = Browser.new_context(browser)
      context = %{context | guid: "bogus"}
      assert {:error, %Error{}} = BrowserContext.clear_permissions(context)
    end

    test "clears previously granted permissions", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.clear_permissions(context)
      BrowserContext.grant_permissions(context, ["notifications"])

      assert get_permission(page, "geolocation") == "denied"
      assert get_permission(page, "notifications") == "granted"
    end

    test "resets permissions", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.clear_permissions(context)
      assert get_permission(page, "geolocation") == "prompt"
    end
  end

  describe "BrowserContext.clear_permissions!/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.owned_context(page)
      assert %BrowserContext{} = BrowserContext.clear_permissions!(context)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.owned_context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.clear_permissions!(context)
      end
    end
  end

  describe "BrowserContext.close/1" do
    @tag exclude: [:page]
    test "is :ok with an empty context", %{browser: browser} do
      context = Browser.new_context(browser)
      assert :ok = BrowserContext.close(context)
    end

    # pending implementation of some equivalent of `wait_helper.reject_on_event(...)`
    # @tag exclude: [:page]
    # test "aborts :wait_for/:expect events", %{browser: browser} do
    #   context = Browser.new_context(browser)

    #   BrowserContext.expect_page(context, fn ->
    #     BrowserContext.close(context)
    #   end)
    # end

    @tag exclude: [:page]
    test "is callable twice", %{browser: browser} do
      context = Browser.new_context(browser)
      assert :ok = BrowserContext.close(context)
      assert :ok = BrowserContext.close(context)
    end

    @tag exclude: [:page]
    test "closes all belonging pages", %{browser: browser} do
      context = Browser.new_context(browser)

      BrowserContext.new_page(context)
      assert length(BrowserContext.pages(context)) == 1

      BrowserContext.close(context)
      assert Enum.empty?(BrowserContext.pages(context))
    end
  end

  describe "BrowserContext.cookies/1" do
    test "retrieves no cookies from a pristine context", %{page: page} do
      cookies = BrowserContext.cookies(page.owned_context)
      assert cookies == []
    end

    test "retrieves cookies for the context", %{assets: assets, page: page} do
      context = Page.owned_context(page)
      page |> Page.goto(assets.empty)

      cookie =
        page
        |> Page.evaluate("""
          () => {
            document.cookie = "username=Jane";
            return document.cookie;
          }
        """)

      assert cookie == "username=Jane"

      assert BrowserContext.cookies(context) == [
               %{
                 domain: "localhost",
                 expires: -1,
                 httpOnly: false,
                 name: "username",
                 path: "/assets",
                 sameSite: "Lax",
                 secure: false,
                 value: "Jane"
               }
             ]
    end

    # test_should_get_a_non_session_cookie
    # test_should_properly_report_httpOnly_cookie
    # test_should_properly_report_strict_sameSite_cookie
    # test_should_properly_report_lax_sameSite_cookie
    # test_should_get_multiple_cookies
    # test_should_get_cookies_from_multiple_urls
  end

  describe "BrowserContext.expect_*/*" do
    # NOTE: skipping while everything is in transition
    @tag exclude: [:page]
    @tag :skip
    test ".expect_page/3", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      %{params: params} =
        BrowserContext.expect_page(context, fn ->
          Page.evaluate(page, "url => window.open(url)", assets.empty)
        end)

      assert Page.url(params.page) == assets.empty
    end
  end

  describe "BrowserContext.expose_binding/4" do
    test "on success, returns the 'subject' `BrowserContext`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.expose_binding(context, "fn", fn -> nil end)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      context = Browser.new_context(browser)

      assert {:error, %Error{message: "name: expected string, got object"}} =
               BrowserContext.expose_binding(context, nil, fn -> nil end)
    end

    test "binds a local function", %{page: page} do
      context = Page.context(page)

      handler = fn source, [a, b] ->
        assert source.frame == Page.main_frame(page)
        a + b
      end

      BrowserContext.expose_binding(context, "add", handler)
      assert Page.evaluate(page, "add(5, 6)") == 11
    end
  end

  describe "BrowserContext.expose_binding!/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.expose_binding!(context, "fn", fn -> nil end)
    end

    test "on failure, raises `RuntimeError`", %{browser: browser} do
      assert_raise RuntimeError, "name: expected string, got object", fn ->
        context = Browser.new_context(browser)
        BrowserContext.expose_binding!(context, nil, fn -> nil end)
      end
    end
  end

  describe "BrowserContext.expose_function/3" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.expose_function(context, "fn", fn -> nil end)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      context = Browser.new_context(browser)

      assert {:error, %Error{message: "name: expected string, got object"}} =
               BrowserContext.expose_function(context, nil, fn -> nil end)
    end

    test "binds a local function", %{page: page} do
      context = Page.context(page)

      handler = fn [a, b] ->
        a + b
      end

      BrowserContext.expose_function(context, "add", handler)
      assert Page.evaluate(page, "add(9, 4)") == 13
    end
  end

  describe "BrowserContext.expose_function!/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.expose_function!(context, "fn", fn -> nil end)
    end

    test "on failure, raises `RuntimeError`", %{browser: browser} do
      assert_raise RuntimeError, "name: expected string, got object", fn ->
        context = Browser.new_context(browser)
        BrowserContext.expose_function!(context, nil, fn -> nil end)
      end
    end
  end

  describe "BrowserContext.grant_permissions/3" do
    test "on success, returns the 'subject' `BrowserContext`", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.grant_permissions(context, [], %{origin: assets.empty})
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser)

      assert {:error, %Error{message: "Unknown permission: bogus"}} =
               BrowserContext.grant_permissions(context, :bogus, %{origin: assets.empty})
    end

    test "prior to granting, defaults to 'prompt'", %{assets: assets, page: page} do
      page |> Page.goto(assets.empty)
      assert get_permission(page, "geolocation") == "prompt"
    end

    test "denies permission when not listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, [], %{origin: assets.empty})
      assert get_permission(page, "geolocation") == "denied"
    end

    test "errors when a bad permission is given", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      assert {:error, %{message: "Unknown permission: foo"}} =
               BrowserContext.grant_permissions(context, ["foo"], %{origin: assets.empty})
    end

    test "grants geolocation permission when origin is listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"], %{origin: assets.empty})
      assert get_permission(page, "geolocation") == "granted"
    end

    test "prompts for geolocation permission when origin is not listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)
      BrowserContext.grant_permissions(context, ["geolocation"], %{origin: assets.empty})

      page |> Page.goto(String.replace(assets.empty, "localhost", "127.0.0.1"))
      assert get_permission(page, "geolocation") == "prompt"
    end

    test "grants notification permission when listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["notifications"], %{origin: assets.empty})
      assert get_permission(page, "notifications") == "granted"
    end

    test "grants permissions when listed for all domains", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      assert get_permission(page, "geolocation") == "granted"
    end

    test "accumulates permissions", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.grant_permissions(context, ["notifications"])

      assert get_permission(page, "geolocation") == "granted"
      assert get_permission(page, "notifications") == "granted"
    end

    @tag exclude: [:page]
    test "grants permissions on `Browser.new_context/1`", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser, %{permissions: ["geolocation"]})
      page = BrowserContext.new_page(context)

      page |> Page.goto(assets.empty)
      assert get_permission(page, "geolocation") == "granted"

      BrowserContext.close(context)
      Page.close(page)
    end
  end

  describe "BrowserContext.grant_permissions!/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.grant_permissions!(context, [], %{origin: assets.empty})
    end

    test "on failure, raises `RuntimeError`", %{assets: assets, browser: browser} do
      assert_raise RuntimeError, "Unknown permission: bogus", fn ->
        context = Browser.new_context(browser)
        BrowserContext.grant_permissions!(context, :bogus, %{origin: assets.empty})
      end
    end
  end

  describe "BrowserContext.new_cdp_session/1" do
    test "on success, returns a `CDPSession`", %{page: page} do
      context = Page.context(page)
      assert %CDPSession{} = BrowserContext.new_cdp_session(context, page)
    end

    test "on failure, returns `{:error, error}`", %{page: page} do
      context = Page.context(page)
      context = %{context | guid: "bogus"}

      assert {:error, %Error{message: "Target page, context or browser has been closed"}} =
               BrowserContext.new_cdp_session(context, page)
    end
  end

  describe "BrowserContext.new_cdp_session!/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %CDPSession{} = BrowserContext.new_cdp_session!(context, page)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.new_cdp_session!(context, page)
      end
    end
  end

  describe "BrowserContext.new_page/1" do
    test "on success, returns a `Page`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %Page{} = BrowserContext.new_page(context)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      context = Browser.new_context(browser)
      context = %{context | guid: "bogus"}

      assert {:error, %Error{message: "Target page, context or browser has been closed"}} =
               BrowserContext.new_page(context)
    end
  end

  describe "BrowserContext.new_page!/1" do
    test "on success, returns a `Page`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %Page{} = BrowserContext.new_page!(context)
    end

    test "on failure, raises `RuntimeError`", %{browser: browser} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Browser.new_context(browser)
        context = %{context | guid: "bogus"}
        BrowserContext.new_page!(context)
      end
    end
  end

  describe "BrowserContext.on/3" do
    test "on success, returns the 'subject' `BrowserContext`", %{browser: browser} do
      context = Browser.new_context(browser)
      assert %BrowserContext{} = BrowserContext.on(context, :foo, fn -> nil end)
    end

    @tag without: [:page]
    test "on :request", %{assets: assets, browser: browser} do
      test_pid = self()

      context = Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      BrowserContext.on(context, "request", fn %{params: %{request: request}} ->
        send(test_pid, request.url)
      end)

      page |> Page.goto(assets.prefix <> "/empty.html")
      page |> Page.set_content("<a target=_blank rel=noopener href='/assets/one-style.html'>yo</a>")

      BrowserContext.expect_event(context, "page", fn ->
        page |> Page.click("a")
      end)

      assert %Page{} = Page.wait_for_load_state(page)

      recv_1 = assets.empty
      recv_2 = assets.prefix <> "/one-style.html"
      # recv_3 = assets.prefix <> "/one-style.css"

      assert_received(^recv_1)
      assert_received(^recv_2)
      # assert_received(^recv_3)
    end
  end

  describe "BrowserContext.pages/1" do
    @tag exclude: [:page]
    test "returns the pages associated with the `BrowserContext`", %{browser: browser} do
      context = Browser.new_context(browser)
      BrowserContext.new_page(context)
      BrowserContext.new_page(context)

      pages = BrowserContext.pages(context)
      assert length(pages) == 2

      BrowserContext.close(context)
    end
  end

  describe "BrowserContext.remove_all_listeners/2" do
  end

  describe "BrowserContext.remove_all_listeners!/2" do
  end

  describe "BrowserContext.route/4" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.route(context, "**/*", fn -> nil end)
    end

    # test "on failure, returns `{:error, error}`", %{page: page} do
    #   context = Page.context(page)
    #   assert {:error, %Error{message: "lala"}} = BrowserContext.route(context, "**/*", fn -> nil end, %{bogus: "option"})
    # end

    test "intercepts requests w/ a glob-style matcher", %{assets: assets, page: page} do
      pid = self()
      context = Page.context(page)

      handler = fn route, request ->
        send(pid, :intercepted)

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
      end

      BrowserContext.route(context, "**/empty.html", handler)
      response = Page.goto(page, assets.empty)

      assert Response.ok(response)
      assert_received(:intercepted)
    end

    test "intercepts requests w/ a regex pattern passed as a Regex", %{assets: assets, page: page} do
      pid = self()
      context = Page.context(page)

      handler = fn route, _request ->
        send(pid, :intercepted)
        Route.continue(route)
      end

      BrowserContext.route(context, ~r/.*\/empty.*/, handler)
      response = Page.goto(page, assets.empty)

      assert Response.ok(response)
      assert_received(:intercepted)
    end

    test "with multiple, rolled-up handlers and `.unroute/1`", %{assets: assets, page: page} do
      pid = self()
      context = Page.context(page)

      handler = fn route, marker ->
        send(pid, marker)
        Route.continue(route)
      end

      handler_4 = fn route, _request ->
        handler.(route, 4)
      end

      BrowserContext.route(context, "**/*", fn route, _request ->
        handler.(route, 1)
      end)

      BrowserContext.route(context, "**/empty.html", fn route, _request ->
        handler.(route, 2)
      end)

      BrowserContext.route(context, "**/empty.html", fn route, _request ->
        handler.(route, 3)
      end)

      BrowserContext.route(context, "**/empty.html", handler_4)

      Page.goto(page, assets.empty)
      BrowserContext.unroute(context, "**/empty.html", handler_4)
      Page.goto(page, assets.empty)
      BrowserContext.unroute(context, "**/empty.html")
      Page.goto(page, assets.empty)

      assert_next_receive(4)
      assert_next_receive(3)
      assert_next_receive(1)
      assert_empty_mailbox()
    end

    test "yields to Page.route", %{assets: assets, page: page} do
      context = Page.context(page)

      BrowserContext.route(context, "**/empty.html", fn route, _ ->
        Route.fulfill(route, %{status: 200, body: "from context"})
      end)

      Page.route(page, "**/empty.html", fn route, _ ->
        Route.fulfill(route, %{status: 200, body: "from page"})
      end)

      response = Page.goto(page, assets.empty)
      assert Response.ok(response)
      assert Response.text(response) == "from page"
    end

    # NOTE:
    # need to find a way for Page.on_route to hand off to BrowserContext.on_route
    #
    # test "falls back to Context.route", %{assets: assets, page: page} do
    #   context = Page.context(page)

    #   BrowserContext.route(context, "**/empty.html", fn route, _ ->
    #     Route.fulfill(route, %{status: 200, body: "from context"})
    #   end)

    #   Page.route(page, "**/non-empty.html", fn route, _ ->
    #     Route.fulfill(route, %{status: 200, body: "from page"})
    #   end)

    #   response = Page.goto(page, assets.empty)
    #   assert Response.ok(response)
    #   assert Response.text!(response) == "from context"
    # end
  end

  describe "BrowserContext.route!/1" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.route!(context, "**/*", fn -> nil end)
    end

    # test "on failure, raises `RuntimeError`", %{browser: browser} do
    #   assert_raise RuntimeError, "...", fn ->
    #     context = Page.context(page)
    #     BrowserContext.route!(context, "**/*", fn -> nil end)
    #   end
    # end
  end

  describe "BrowserContext.route_from_har/1" do
    # test "...", %{assets: assets, browser: browser} do
    #   context =
    #     Browser.new_context(browser)
    #     |> BrowserContext.route_from_har(assets.prefix <> "har-fulfill.har")

    #   page =
    #     BrowserContext.new_page(context)
    #     |> Page.goto("http://no.playwright/")

    #   assert "foo" = Page.evaluate(page, "window.value")
    # end
  end

  describe "BrowserContext.route_from_har!/1" do
  end

  describe "BrowserContext.route_web_socket/1" do
  end

  describe "BrowserContext.route_web_socket!/1" do
  end

  describe "BrowserContext.service_workers/1" do
  end

  describe "BrowserContext.set_default_navigation_timeout/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_default_navigation_timeout(context, 5)
    end

    test "on failure, returns `{:error, error}`", %{page: page} do
      context = Page.context(page)
      context = %{context | guid: "bogus"}

      assert {:error, %Error{message: "Target page, context or browser has been closed"}} =
               BrowserContext.set_default_navigation_timeout(context, 5)
    end

    test "causes `Page.goto/3` to fail when exceeding the timeout", %{assets: assets, page: page} do
      context = Page.context(page)

      BrowserContext.route(context, "**/*", fn _, _ ->
        :timer.sleep(3)
      end)

      BrowserContext.set_default_navigation_timeout(context, 5)
      assert {:error, %Error{message: "Timeout 5ms exceeded."}} = Page.goto(page, assets.empty)
    end
  end

  describe "BrowserContext.set_default_navigation_timeout!/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_default_navigation_timeout!(context, 5)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.set_default_navigation_timeout!(context, 5)
      end
    end
  end

  describe "BrowserContext.set_default_timeout/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_default_timeout(context, 5)
    end

    test "on failure, returns `{:error, error}`", %{page: page} do
      context = Page.context(page)
      context = %{context | guid: "bogus"}

      assert {:error, %Error{message: "Target page, context or browser has been closed"}} =
               BrowserContext.set_default_timeout(context, 5)
    end

    test "causes `Page.goto/3` to fail when exceeding the timeout", %{assets: assets, page: page} do
      context = Page.context(page)

      BrowserContext.route(context, "**/*", fn _, _ ->
        :timer.sleep(3)
      end)

      BrowserContext.set_default_timeout(context, 5)
      assert {:error, %Error{message: "Timeout 5ms exceeded."}} = Page.goto(page, assets.empty)
    end
  end

  describe "BrowserContext.set_default_timeout!/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_default_timeout!(context, 5)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.set_default_timeout!(context, 5)
      end
    end
  end

  describe "BrowserContext.set_extra_http_headers/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{assets: assets, page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_extra_http_headers(context, %{referer: assets.empty})
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, page: page} do
      context = Page.context(page)
      context = %{context | guid: "bogus"}

      assert {:error, %Error{message: "Target page, context or browser has been closed"}} =
               BrowserContext.set_extra_http_headers(context, %{referer: assets.empty})
    end

    test "sends custom headers with subsequent requests", %{assets: assets, page: page} do
      pid = self()
      empty = assets.empty

      context = Page.context(page)
      BrowserContext.set_extra_http_headers(context, %{referer: assets.empty})

      BrowserContext.route(context, "**/*", fn route, _request ->
        request = Route.request(route)
        headers = Request.headers(request)

        referer =
          Enum.find(headers, fn header ->
            header.name == "referer"
          end)

        send(pid, %{referer: referer.value})
        Route.continue(route)
      end)

      Page.goto(page, assets.empty)
      assert_received(%{referer: ^empty})
    end
  end

  describe "BrowserContext.set_extra_http_headers!/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{assets: assets, page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_extra_http_headers!(context, %{referer: assets.empty})
    end

    test "on failure, raises `RuntimeError`", %{assets: assets, page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.set_extra_http_headers!(context, %{referer: assets.empty})
      end
    end
  end

  # skip: See documentation comment for `BrowserContext.set_geolocation/2`
  describe "BrowserContext.set_geolocation/2" do
    @tag :skip
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_geolocation(context, nil)
    end

    @tag :skip
    test "on failure, returns `{:error, error}`", %{page: page} do
      context = Page.context(page)
      context = %{context | guid: "bogus"}

      assert {:error, %Error{message: "Target page, context or browser has been closed"}} =
               BrowserContext.set_geolocation(context, %{})
    end

    @tag :skip
    test "mimics geolocation settings in the browser context", %{assets: assets, page: page} do
      context = Page.context(page)
      BrowserContext.grant_permissions(context, ["geolocation"])

      BrowserContext.set_geolocation(context, %{latitude: 10, longitude: 10})

      Page.goto(page, assets.empty)

      geolocation =
        Page.evaluate(page, """
          async() => new Promise(resolve => navigator.geolocation.getCurrentPosition(position => {
           resolve({latitude: position.coords.latitude, longitude: position.coords.longitude});
           }))
        """)

      assert %{latitude: 10, longitude: 10} = geolocation
    end
  end

  @tag :skip
  describe "BrowserContext.set_geolocation!/2" do
    @tag :skip
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_geolocation!(context, %{latitude: 0, longitude: 0})
    end

    @tag :skip
    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.set_geolocation!(context, %{latitude: 0, longitude: 0})
      end
    end
  end

  describe "BrowserContext.set_offline/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_offline(context, false)
      assert %BrowserContext{} = BrowserContext.set_offline(context, true)
    end

    test "on failure, returns `{:error, error}`", %{page: page} do
      context = Page.context(page)
      context = %{context | guid: "bogus"}

      assert {:error, %Error{message: "Target page, context or browser has been closed"}} =
               BrowserContext.set_offline(context, true)
    end

    @tag without: [:page]
    test "using initial option", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser, %{offline: true})
      page = BrowserContext.new_page(context)

      assert {:error, error} = Page.goto(page, assets.empty)
      assert String.contains?(error.message, "net::ERR_INTERNET_DISCONNECTED")

      BrowserContext.set_offline(context, false)
      response = Page.goto(page, assets.empty)
      assert Response.ok(response)

      BrowserContext.close(context)
    end

    test "emulating navigator.onLine", %{page: page} do
      context = Page.context(page)
      assert Page.evaluate(page, "window.navigator.onLine")

      BrowserContext.set_offline(context, true)
      refute Page.evaluate(page, "window.navigator.onLine")

      BrowserContext.set_offline(context, false)
      assert Page.evaluate(page, "window.navigator.onLine")
    end
  end

  describe "BrowserContext.set_offline!/2" do
    test "on success, returns the 'subject' `BrowserContext`", %{page: page} do
      context = Page.context(page)
      assert %BrowserContext{} = BrowserContext.set_offline!(context, false)
      assert %BrowserContext{} = BrowserContext.set_offline!(context, true)
    end

    test "on failure, raises `RuntimeError`", %{page: page} do
      assert_raise RuntimeError, "Target page, context or browser has been closed", fn ->
        context = Page.context(page)
        context = %{context | guid: "bogus"}
        BrowserContext.set_offline!(context, true)
      end
    end
  end

  describe "BrowserContext.storage_state/2" do
    test "on success, returns storage state JSON", %{browser: browser} do
      storage = %{
        cookies: [
          %{
            name: "cookie name",
            value: "cookie value",
            domain: "example.com",
            path: "/",
            expires: -1,
            httpOnly: false,
            secure: false,
            sameSite: "Lax"
          }
        ],
        origins: []
      }

      context = Browser.new_context(browser, %{storage_state: storage})
      assert ^storage = BrowserContext.storage_state(context)
    end

    test "on failure, returns `{:error, error}`", %{browser: browser} do
      context = Browser.new_context(browser, %{storage_state: %{}})
      context = %{context | guid: "bogus"}
      assert {:error, %Error{}} = BrowserContext.storage_state(context)
    end

    test "given the `:path` option, writes the state to disk", %{browser: browser} do
      slug = DateTime.utc_now() |> DateTime.to_unix()
      path = "storage-state-#{slug}.json"

      storage = %{
        cookies: [
          %{
            name: "cookie name",
            value: "cookie value",
            domain: "example.com",
            path: "/",
            expires: -1,
            httpOnly: false,
            secure: false,
            sameSite: "Lax"
          }
        ],
        origins: []
      }

      context = Browser.new_context(browser, %{storage_state: storage})

      assert ^storage = BrowserContext.storage_state(context, %{path: path})
      assert(File.exists?(path))
      assert(Jason.decode!(File.read!(path)))

      File.rm!(path)
    end
  end

  describe "BrowserContext.unroute/2" do
  end

  describe "BrowserContext.unroute!/2" do
  end

  describe "BrowserContext.unroute_all/2" do
  end

  describe "BrowserContext.unroute_all!/2" do
  end

  describe "BrowserContext.wait_for_event/2" do
  end

  describe "BrowserContext.wait_for_event!/2" do
  end

  # private helpers
  # ----------------------------------------------------------------------------

  defp get_permission(page, name) do
    Page.evaluate(page, "(name) => navigator.permissions.query({name: name}).then(result => result.state)", name)
  end
end

# BrowserContext.storage_state/2
# - test_should_capture_local_storage
# - test_should_set_local_storage
# - test_should_round_trip_through_the_file

# ...
# test_expose_function_should_throw_for_duplicate_registrations
# test_expose_function_should_be_callable_from_inside_add_init_script
# test_expose_bindinghandle_should_work
# test_window_open_should_use_parent_tab_context
# test_page_event_should_isolate_localStorage_and_cookies
# test_page_event_should_propagate_default_viewport_to_the_page
# test_page_event_should_respect_device_scale_factor
# test_page_event_should_not_allow_device_scale_factor_with_null_viewport
# test_page_event_should_not_allow_is_mobile_with_null_viewport
# test_user_agent_should_work
# test_user_agent_should_work_for_subframes
# test_user_agent_should_emulate_device_user_agent
# test_user_agent_should_make_a_copy_of_default_options
# test_page_event_should_bypass_csp_meta_tag
# test_page_event_should_bypass_csp_header
# test_page_event_should_bypass_after_cross_process_navigation
# test_page_event_should_bypass_csp_in_iframes_as_well
# test_csp_should_work
# test_csp_should_be_able_to_navigate_after_disabling_javascript
# test_auth_should_fail_without_credentials
# test_auth_should_work_with_correct_credentials
# test_auth_should_fail_with_wrong_credentials
# test_auth_should_return_resource_body
# test_offline_should_work_with_initial_option
# test_offline_should_emulate_navigator_online
# test_page_event_should_have_url
# test_page_event_should_have_url_after_domcontentloaded
# test_page_event_should_have_about_blank_url_with_domcontentloaded
# test_page_event_should_have_about_blank_for_empty_url_with_domcontentloaded
# test_page_event_should_report_when_a_new_page_is_created_and_closed
# test_page_event_should_report_initialized_pages
# test_page_event_should_have_an_opener
# test_page_event_should_fire_page_lifecycle_events
# test_page_event_should_work_with_shift_clicking
# test_page_event_should_work_with_ctrl_clicking
# test_strict_selectors_on_context
# test_should_support_forced_colors
