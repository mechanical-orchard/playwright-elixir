defmodule Playwright.Page.ExpectTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page.expect_event/2" do
  #   test "events are fired in the proper order", %{assets: assets, page: page} do
  #     pid = self()
  #     url = assets.empty

  #     Page.on(page, "request", fn _, %{params: %{request: request}} ->
  #       send(pid, {:request, request.url})
  #     end)

  #     Page.on(page, "response", fn _, %{params: %{response: response}} ->
  #       send(pid, {:response, response.url})
  #     end)

  #     Page.on(page, "requestFinished", fn _, %{params: %{request: request}} ->
  #       send(pid, {:finished, request.url})
  #     end)

  #     Page.goto(page, url)
  #     assert_next_receive({:request, ^url})
  #     assert_next_receive({:response, ^url})
  #     assert_next_receive({:finished, ^url})
  #   end
  end
end

# ---

# async def test_wait_for_event_should_fail_with_error_upon_disconnect(page):
#     with pytest.raises(Error) as exc_info:
#         async with page.expect_download():
#             await page.close()
#     assert "Page closed" in exc_info.value.message


# async def wait_for_event(
#   self, event: str, predicate: Callable = None, timeout: float = None
# ) -> Any:
#   async with self.expect_event(event, predicate, timeout) as event_info:
#       pass
#   return await event_info

# def expect_event(
#   self,
#   event: str,
#   predicate: Callable = None,
#   timeout: float = None,
# ) -> EventContextManagerImpl:
#   return self._expect_event(
#       event, predicate, timeout, f'waiting for event "{event}"'
#   )

# def _expect_event(
#   self,
#   event: str,
#   predicate: Callable = None,
#   timeout: float = None,
#   log_line: str = None,
# ) -> EventContextManagerImpl:
#   if timeout is None:
#       timeout = self._timeout_settings.timeout()
#   wait_helper = WaitHelper(self, f"page.expect_event({event})")
#   wait_helper.reject_on_timeout(
#       timeout, f'Timeout while waiting for event "{event}"'
#   )
#   if log_line:
#       wait_helper.log(log_line)
#   if event != Page.Events.Crash:
#       wait_helper.reject_on_event(self, Page.Events.Crash, Error("Page crashed"))
#   if event != Page.Events.Close:
#       wait_helper.reject_on_event(self, Page.Events.Close, Error("Page closed"))
#   wait_helper.wait_for_event(self, event, predicate)
#   return EventContextManagerImpl(wait_helper.result())

# -------------------------

# def wait_for_load_state(_subject, _options \\ %{}) do
#   # frame(subject) |> Channel.send("waitForSelector", Map.merge(%{selector: selector}, options))
# end

# async waitForRequest(urlOrPredicate: string | RegExp | ((r: Request) => boolean | Promise<boolean>), options: { timeout?: number } = {}): Promise<Request> {
#   return this._wrapApiCall(async (channel: channels.PageChannel) => {
#     const predicate = (request: Request) => {
#       if (isString(urlOrPredicate) || isRegExp(urlOrPredicate))
#         return urlMatches(this._browserContext._options.baseURL, request.url(), urlOrPredicate);
#       return urlOrPredicate(request);
#     };
#     const trimmedUrl = trimUrl(urlOrPredicate);
#     const logLine = trimmedUrl ? `waiting for request ${trimmedUrl}` : undefined;
#     return this._waitForEvent(channel, Events.Page.Request, { predicate, timeout: options.timeout }, logLine);
#   });
# }

#   def expect_request(
#     self,
#     url_or_predicate: URLMatchRequest,
#     timeout: float = None,
# ) -> EventContextManagerImpl[Request]:
#     matcher = (
#         None
#         if callable(url_or_predicate)
#         else URLMatcher(
#             self._browser_context._options.get("baseURL"), url_or_predicate
#         )
#     )
#     predicate = url_or_predicate if callable(url_or_predicate) else None

#     def my_predicate(request: Request) -> bool:
#         if matcher:
#             return matcher.matches(request.url)
#         if predicate:
#             return predicate(request)
#         return True

#     trimmed_url = trim_url(url_or_predicate)
#     log_line = f"waiting for request {trimmed_url}" if trimmed_url else None
#     return self._expect_event(
#         Page.Events.Request,
#         predicate=my_predicate,
#         timeout=timeout,
#         log_line=log_line,
#     )

# -------------------------

# def expect_event(
# def expect_console_message(
# def expect_download(
# def expect_file_chooser(
# def expect_navigation(
# def expect_popup(
# def expect_request(
# def expect_request_finished(
# def expect_response(
# def expect_websocket(
# def expect_worker(

# def wait_for_selector(
# def wait_for_load_state(
# def wait_for_url(
# def wait_for_event(
# def wait_for_timeout(self, timeout: float) -> None:
# def wait_for_function(

# --------------------------

# async def test_wait_for_request(page, server):
# async def test_wait_for_request_should_work_with_predicate(page, server):
# async def test_wait_for_request_should_timeout(page, server):
# async def test_wait_for_request_should_respect_default_timeout(page, server):
# async def test_wait_for_request_should_work_with_no_timeout(page, server):
# async def test_wait_for_request_should_work_with_url_match(page, server):
# async def test_wait_for_event_should_fail_with_error_upon_disconnect(page):
# async def test_wait_for_response_should_work(page, server):
# async def test_wait_for_response_should_respect_timeout(page):
# async def test_wait_for_response_should_respect_default_timeout(page):
# async def test_wait_for_response_should_work_with_predicate(page, server):
# async def test_wait_for_response_should_work_with_no_timeout(page, server):

# async def test_wait_for_request(page, server):
# await page.goto(server.EMPTY_PAGE)
# async with page.expect_request(server.PREFIX + "/digits/2.png") as request_info:
#     await page.evaluate(
#         """() => {
#             fetch('/digits/1.png')
#             fetch('/digits/2.png')
#             fetch('/digits/3.png')
#         }"""
#     )
# request = await request_info.value
# assert request.url == server.PREFIX + "/digits/2.png"

# test ".expect_request/2", %{assets: assets, page: page} do
#   Page.goto(page, assets.empty)
#   Page.expect_request(page, assets.prefix <> "/digits/2.png")
# end
