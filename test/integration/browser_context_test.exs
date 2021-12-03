defmodule Playwright.BrowserContextTest do
  use Playwright.TestCase
  alias Playwright.{Browser, BrowserContext, Page}

  describe "Browser.new_context/1" do
    @tag exclude: [:page]
    test "creates and binds a new context", %{browser: browser} do
      assert Browser.contexts(browser) == {:ok, []}

      {:ok, _} = Browser.new_context(browser)
      assert {:ok, [%BrowserContext{} = context]} = Browser.contexts(browser)
      assert context.browser == browser

      BrowserContext.close(context)
      assert Browser.contexts(browser) == {:ok, []}
    end
  end

  describe "Browser.new_page/1" do
    @tag exclude: [:page]
    test "creates and binds a new context", %{browser: browser} do
      assert Browser.contexts(browser) == {:ok, []}

      {:ok, page} = Browser.new_page(browser)
      assert {:ok, [%BrowserContext{} = context]} = Browser.contexts(browser)
      assert context.browser == browser

      Page.close(page)
      assert Browser.contexts(browser) == {:ok, []}
    end
  end

  describe "BrowserContext.browser/1" do
    test "returns the Browser", %{browser: browser, page: page} do
      context = Page.context(page)
      assert BrowserContext.browser(context) == browser
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
    #   context = Browser.new_context!(browser)

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
      context = Browser.new_context!(browser)

      {:ok, _} = BrowserContext.new_page(context)
      assert length(BrowserContext.pages!(context)) == 1

      BrowserContext.close(context)
      assert length(BrowserContext.pages!(context)) == 0
    end
  end

  describe "BrowserContext.expose_binding/4" do
    test "binds a local function", %{page: page} do
      context = Page.context(page)

      handler = fn source, [a, b] ->
        assert source.frame == Page.main_frame(page)
        a + b
      end

      BrowserContext.expose_binding(context, "add", handler)
      assert Page.evaluate!(page, "add(5, 6)") == 11
    end
  end

  describe "BrowserContext.expose_function/3" do
    test "binds a local function", %{page: page} do
      context = Page.context(page)

      handler = fn [a, b] ->
        a + b
      end

      BrowserContext.expose_function(context, "add", handler)
      assert Page.evaluate!(page, "add(9, 4)") == 13
    end
  end

  describe "BrowserContext.pages/1" do
    @tag exclude: [:page]
    test "returns the pages", %{browser: browser} do
      context = Browser.new_context!(browser)
      {:ok, _} = BrowserContext.new_page(context)
      {:ok, _} = BrowserContext.new_page(context)

      {:ok, pages} = BrowserContext.pages(context)
      assert length(pages) == 2

      BrowserContext.close(context)
    end
  end

  # ---

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
  # test_route_should_intercept
  # test_route_should_unroute
  # test_route_should_yield_to_page_route
  # test_route_should_fall_back_to_context_route
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
end
