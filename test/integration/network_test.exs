defmodule Playwright.Page.NetworkTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Page}

  describe "Page network events" do
    test "events are fired in the proper order", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "request", fn _, %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.on(page, "response", fn _, %{params: %{response: response}} ->
        send(pid, {:response, response.url})
      end)

      # Page.on(page, "requestFinished", fn _, %{params: %{request: request}} ->
      Page.on(page, "requestFinished", fn _, %{params: %{request: request}} ->
        send(pid, {:finished, request.url})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, ^url})
      assert_next_receive({:response, ^url})
      assert_next_receive({:finished, ^url})
    end

    test "request finished event", %{assets: assets, page: page} do
      # event_info = Page.expect_event(page, "requestFinished")
      # Page.goto(page, assets.empty)

      # request = event_info.value
      # assert request.url == assets.empty

      url = assets.empty

      # response = Page.expect_event(page, "bogus", fn page ->
      event_info = Page.expect_event(page, "requestFinished", fn _ ->
        Page.goto(page, url)
      end)
      # |> IO.inspect(label: "event info")

      response = event_info.response

      assert response.url == url

      # request = Response.request(response)
      # assert request.url = url
      # assert Request.response(request)

      # frame = Request.frame(request)
      # assert frame == Page.main_frame(page)
      # assert frame.url == url

      # refute Request.failure(request)
    end
  end
end

#   const [response] = await Promise.all([
#     page.goto(server.EMPTY_PAGE),
#     page.waitForEvent('requestfinished')
#   ]);
#   const request = response.request();
#   expect(request.url()).toBe(server.EMPTY_PAGE);
#   expect(await request.response()).toBeTruthy();
#   expect(request.frame() === page.mainFrame()).toBe(true);
#   expect(request.frame().url()).toBe(server.EMPTY_PAGE);
#   expect(request.failure()).toBe(null);

# """Page.expect_event

# Waits for event to fire and passes its value into the predicate function. Returns when the predicate returns truthy
# value. Will throw an error if the page is closed before the event is fired. Returns the event data value.

# ```py
# async with page.expect_event(\"framenavigated\") as event_info:
#     await page.click(\"button\")
# frame = await event_info.value
# ```

# Parameters
# ----------
# event : str
#     Event name, same one typically passed into `*.on(event)`.
# predicate : Union[Callable, NoneType]
#     Receives the event data and resolves to truthy value when the waiting should resolve.
# timeout : Union[float, NoneType]
#     Maximum time to wait for in milliseconds. Defaults to `30000` (30 seconds). Pass `0` to disable timeout. The default
#     value can be changed by using the `browser_context.set_default_timeout()`.

# Returns
# -------
# EventContextManager
# """

# """Page.wait_for_event

# > NOTE: In most cases, you should use `page.expect_event()`.

# Waits for given `event` to fire. If predicate is provided, it passes event's value into the `predicate` function and
# waits for `predicate(event)` to return a truthy value. Will throw an error if the page is closed before the `event` is
# fired.

# Parameters
# ----------
# event : str
#     Event name, same one typically passed into `*.on(event)`.
# predicate : Union[Callable, NoneType]
#     Receives the event data and resolves to truthy value when the waiting should resolve.
# timeout : Union[float, NoneType]
#     Maximum time to wait for in milliseconds. Defaults to `30000` (30 seconds). Pass `0` to disable timeout. The default
#     value can be changed by using the `browser_context.set_default_timeout()`.

# Returns
# -------
# Any
# """

# it('Page.Events.RequestFinished', async ({ page, server }) => {
#   const [response] = await Promise.all([
#     page.goto(server.EMPTY_PAGE),
#     page.waitForEvent('requestfinished')
#   ]);
#   const request = response.request();
#   expect(request.url()).toBe(server.EMPTY_PAGE);
#   expect(await request.response()).toBeTruthy();
#   expect(request.frame() === page.mainFrame()).toBe(true);
#   expect(request.frame().url()).toBe(server.EMPTY_PAGE);
#   expect(request.failure()).toBe(null);
# });

# it('should fire orientationchange event', async ({ browser, server }) => {
#   const context = await browser.newContext({ viewport: { width: 300, height: 400 }, isMobile: true });
#   const page = await context.newPage();
#   await page.goto(server.PREFIX + '/mobile.html');
#   await page.evaluate(() => {
#     let counter = 0;
#     window.addEventListener('orientationchange', () => console.log(++counter));
#   });

#   const event1 = page.waitForEvent('console');
#   await page.setViewportSize({ width: 400, height: 300 });
#   expect((await event1).text()).toBe('1');

#   const event2 = page.waitForEvent('console');
#   await page.setViewportSize({ width: 300, height: 400 });
#   expect((await event2).text()).toBe('2');
#   await context.close();
# });

# async def test_network_events_request_finished(page, server):
#     async with page.expect_event("requestfinished") as event_info:
#         await page.goto(server.EMPTY_PAGE)
#     request = await event_info.value
#     assert request.url == server.EMPTY_PAGE
#     assert await request.response()
#     assert request.frame == page.main_frame
#     assert request.frame.url == server.EMPTY_PAGE
