defmodule Playwright.Network.RequestTest do
  use Playwright.TestCase, async: true

  alias Playwright.{BrowserContext, Page}
  alias Playwright.Runner.Channel

  describe "Page.on(_, event, _) for `request` event" do
    test "fires for navigation requests", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "request", fn _, %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, ^url})
    end

    test "accepts a callback", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      fun = fn resource, event ->
        send(pid, {resource, event})
      end

      Page.on(page, "request", fun)
      Page.goto(page, url)

      assert_next_receive({%BrowserContext{}, %Channel.Event{type: :request}})
    end

    test "fires for iframes", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "request", fn _, %{params: %{request: request}} ->
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

      Page.on(page, "request", fn _, %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.goto(page, url)
      Page.evaluate(page, "() => { fetch('#{url}') }")

      assert_next_receive({:request, ^url})
      assert_next_receive({:request, ^url})
    end
  end
end


# test "reports requests and responses handled by a service worker", %{assets: assets, page: page} do
#   # pid = self()
#   # url = assets.empty

#   # Page.on(page, "request", fn _, %{params: %{request: request}} ->
#   #   send(pid, {:request, request.url})
#   # end)

#   # Page.goto(page, url)
#   # Page.evaluate(page, "() => { fetch('#{url}') }")

#   # assert_next_receive({:request, ^url})
#   # assert_next_receive({:request, ^url})

#   Page.goto(page, assets.prefix <> "/serviceworkers/fetchdummy/sw.html")
#   Page.evaluate(page, "() => window.activationPromise")

#   Page.expect_request("**/*")
#   |> IO.inspect()
# end
# async def test_page_events_request_should_report_requests_and_responses_handled_by_service_worker(

# it('should report requests and responses handled by service worker', async ({ page, server, isAndroid, isElectron }) => {
#   it.fixme(isAndroid);
#   it.fixme(isElectron);

#   await page.goto(server.PREFIX + '/serviceworkers/fetchdummy/sw.html');
#   await page.evaluate(() => window['activationPromise']);
#   const [swResponse, request] = await Promise.all([
#     page.evaluate(() => window['fetchDummy']('foo')),
#     page.waitForEvent('request'),
#   ]);
#   expect(swResponse).toBe('responseFromServiceWorker:foo');
#   expect(request.url()).toBe(server.PREFIX + '/serviceworkers/fetchdummy/foo');
#   const response = await request.response();
#   expect(response.url()).toBe(server.PREFIX + '/serviceworkers/fetchdummy/foo');
#   expect(await response.text()).toBe('responseFromServiceWorker:foo');
# });

#   async def test_page_events_request_should_report_requests_and_responses_handled_by_service_worker(
#     page: Page, server
# ):
#     await page.goto(server.PREFIX + "/serviceworkers/fetchdummy/sw.html")
#     await page.evaluate("() => window.activationPromise")
#     sw_response = None
#     async with page.expect_request("**/*") as request_info:
#         sw_response = await page.evaluate('() => fetchDummy("foo")')
#     request = await request_info.value
#     assert sw_response == "responseFromServiceWorker:foo"
#     assert request.url == server.PREFIX + "/serviceworkers/fetchdummy/foo"
#     response = await request.response()
#     assert response
#     assert response.url == server.PREFIX + "/serviceworkers/fetchdummy/foo"
#     assert await response.text() == "responseFromServiceWorker:foo"




# async def test_request_frame_should_work_for_main_frame_navigation_request(
# async def test_request_frame_should_work_for_subframe_navigation_request(
# async def test_request_frame_should_work_for_fetch_requests(page, server):
# async def test_request_headers_should_work(
# async def test_request_headers_should_get_the_same_headers_as_the_server(
# async def test_request_headers_should_get_the_same_headers_as_the_server_cors(
# async def test_should_report_request_headers_array(
# async def test_should_report_response_headers_array(
# async def test_response_headers_should_work(page: Page, server):
# async def test_request_post_data_should_work(page, server):
# async def test_request_post_data__should_be_undefined_when_there_is_no_post_data(
# async def test_should_parse_the_json_post_data(page, server):
# async def test_should_parse_the_data_if_content_type_is_form_urlencoded(page, server):
# async def test_should_be_undefined_when_there_is_no_post_data(page, server):
# async def test_should_return_post_data_without_content_type(page, server):
# async def test_should_throw_on_invalid_json_in_post_data(page, server):
# async def test_should_work_with_binary_post_data(page, server):
# async def test_should_work_with_binary_post_data_and_interception(page, server):
# async def test_response_text_should_work(page, server):
# async def test_response_text_should_return_uncompressed_text(page, server):
# async def test_response_text_should_throw_when_requesting_body_of_redirected_response(
# async def test_response_json_should_work(page, server):
# async def test_response_body_should_work(page, server, assetdir):
# async def test_response_body_should_work_with_compression(page, server, assetdir):
# async def test_response_status_text_should_work(page, server):
# async def test_request_resource_type_should_return_event_source(page, server):
# async def test_network_events_request(page, server):
# async def test_network_events_response(page, server):
# async def test_network_events_request_failed(
# async def test_network_events_request_finished(page, server):
# async def test_network_events_should_fire_events_in_proper_order(page, server):
# async def test_network_events_should_support_redirects(page, server):
# async def test_request_is_navigation_request_should_work(page, server):
# async def test_request_is_navigation_request_should_work_when_navigating_to_image(
# async def test_set_extra_http_headers_should_work(page, server):
# async def test_set_extra_http_headers_should_work_with_redirects(page, server):
# async def test_set_extra_http_headers_should_work_with_extra_headers_from_browser_context(
# async def test_set_extra_http_headers_should_override_extra_headers_from_browser_context(
# async def test_set_extra_http_headers_should_throw_for_non_string_header_values(
# async def test_response_server_addr(page: Page, server: Server):
# async def test_response_security_details(
# async def test_response_security_details_none_without_https(page: Page, server: Server):
