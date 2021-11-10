defmodule Playwright.NavigationTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page
  alias Playwright.Response

  describe "Page.goto/2" do
    # setup :target_urls

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
      assert_raise(RuntimeError, "Protocol error (Page.navigate): Cannot navigate to invalid URL", fn ->
        Page.goto(page, "asdfasdf")
      end)
    end

    test "works when navigating to valid URL", %{assets: assets, page: page} do
      response = Page.goto(page, assets.empty)
      assert Response.ok(response)
    end
  end

  # private: setup helpers
  # ---------------------------------------------------------------------------

  # defp target_urls(%{assets: assets, page: _page}) do
  #   [assets: %{blank: "about:blank", empty: assets.prefix <> "/empty.html"}]
  # end
end

# - [x] async def test_goto_should_work(page, server):
# - [ ] async def test_goto_should_work_with_file_URL(page, server, assetdir):
# - [ ] async def test_goto_should_use_http_for_no_protocol(page, server):
# - [ ] async def test_goto_should_work_cross_process(page, server):
# - [ ] async def test_goto_should_capture_iframe_navigation_request(page, server):
# - [ ] async def test_goto_should_capture_cross_process_iframe_navigation_request(
# - [x] async def test_goto_should_work_with_anchor_navigation(page, server):
# - [ ] async def test_goto_should_work_with_redirects(page, server):
# - [x] async def test_goto_should_navigate_to_about_blank(page, server):
# - [x] async def test_goto_should_return_response_when_page_changes_its_url_after_load(
# - [ ] async def test_goto_should_work_with_subframes_return_204(page, server):
# - [ ] async def test_goto_should_fail_when_server_returns_204(
# - [!] async def test_goto_should_navigate_to_empty_page_with_domcontentloaded(page, server):
# - [x] async def test_goto_should_work_when_page_calls_history_api_in_beforeunload(
# - [x] async def test_goto_should_fail_when_navigating_to_bad_url(
# - [ ] async def test_goto_should_fail_when_navigating_to_bad_ssl(
# - [ ] async def test_goto_should_fail_when_navigating_to_bad_ssl_after_redirects(
# - [ ] async def test_goto_should_not_crash_when_navigating_to_bad_ssl_after_a_cross_origin_navigation(
# - [ ] async def test_goto_should_throw_if_networkidle2_is_passed_as_an_option(page, server):
# - [ ] async def test_goto_should_fail_when_main_resources_failed_to_load(
# - [ ] async def test_goto_should_fail_when_exceeding_maximum_navigation_timeout(page, server):
# - [ ] async def test_goto_should_fail_when_exceeding_default_maximum_navigation_timeout(
# - [ ] async def test_goto_should_fail_when_exceeding_browser_context_navigation_timeout(
# - [ ] async def test_goto_should_fail_when_exceeding_default_maximum_timeout(page, server):
# - [ ] async def test_goto_should_fail_when_exceeding_browser_context_timeout(page, server):
# - [ ] async def test_goto_should_prioritize_default_navigation_timeout_over_default_timeout(
# - [ ] async def test_goto_should_disable_timeout_when_its_set_to_0(page, server):
# - [x] async def test_goto_should_work_when_navigating_to_valid_url(page, server):
# - [ ] async def test_goto_should_work_when_navigating_to_data_url(page, server):
# - [ ] async def test_goto_should_work_when_navigating_to_404(page, server):
# - [ ] async def test_goto_should_return_last_response_in_redirect_chain(page, server):
# - [ ] async def test_goto_should_navigate_to_data_url_and_not_fire_dataURL_requests(
# - [ ] async def test_goto_should_navigate_to_url_with_hash_and_fire_requests_without_hash(
# - [ ] async def test_goto_should_work_with_self_requesting_page(page, server):
# - [ ] async def test_goto_should_fail_when_navigating_and_show_the_url_at_the_error_message(
# - [ ] async def test_goto_should_be_able_to_navigate_to_a_page_controlled_by_service_worker(
# - [ ] async def test_goto_should_send_referer(page, server):
# - [ ] async def test_goto_should_reject_referer_option_when_set_extra_http_headers_provides_referer(
# - [ ] async def test_goto_should_work_with_commit(page: Page, server):
