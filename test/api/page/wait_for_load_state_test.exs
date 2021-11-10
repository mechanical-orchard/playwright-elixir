defmodule Test.Page.WaitForLoadStateTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page

  # async def test_wait_for_load_state_should_respect_timeout(page, server):
  # requests = []

  # def handler(request: Any):
  #     requests.append(request)

  # server.set_route("/one-style.css", handler)

  # await page.goto(server.PREFIX + "/one-style.html", wait_until="domcontentloaded")
  # with pytest.raises(Error) as exc_info:
  #     await page.wait_for_load_state("load", timeout=1)
  # assert "Timeout 1ms exceeded." in exc_info.value.message


  # it('should pick up ongoing navigation', async ({ page, server }) => {
  #   let response = null;
  #   server.setRoute('/one-style.css', (req, res) => response = res);
  #   await Promise.all([
  #     server.waitForRequest('/one-style.css'),
  #     page.goto(server.PREFIX + '/one-style.html', { waitUntil: 'domcontentloaded' }),
  #   ]);
  #   const waitPromise = page.waitForLoadState();
  #   response.statusCode = 404;
  #   response.end('Not found');
  #   await waitPromise;
  # });

  describe "Page.wait_for_load_state/3" do
    # test "picks up ongoing navigation", %{assets: assets, page: page} do
    #   Page.route(page, "**/one-style.css", fn (route, request) ->
    #     # ...
    #   end)
    # end


    # test "respects timeout", %{assets: assets, page: page} do
    #   this = self()
    # end

    test "resolves immediately if loaded", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/one-style.html")
      Page.wait_for_load_state(page)
      assert true
    end
  end
end

# this = self()

# context = Browser.new_context(browser)
# page = BrowserContext.new_page(context)

# BrowserContext.on(context, "request", fn {:on, :request, request} ->
#   send(this, request.url)
# end)

# Page.goto(page, assets.prefix <> "/empty.html")
# Page.set_content(page, "<a target=_blank rel=noopener href='/one-style.html'>yo</a>")
# Page.click(page, "a")

# # BrowserContext.wait_for_event(context, "page")
# Page.wait_for_loadstate(page)

# assert_received("http://localhost:3002/empty.html")
# assert_received("http://localhost:3002/one-style.html")
# assert_received("http://localhost:3002/one-style.css")
