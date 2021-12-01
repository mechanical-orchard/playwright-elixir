defmodule Playwright.Page.RouteTest do
  use Playwright.TestCase
  alias Playwright.{Page, Response, Route}

  describe "Page.route/3" do
    test "intercepts requests", %{assets: assets, page: page} do
      this = self()

      Page.route(page, "**/empty.html", fn route, request ->
        assert route.request.guid == request.guid
        assert String.contains?(request.url, "empty.html")
        assert request.method == "GET"
        assert request.post_data == nil
        assert request.is_navigation_request == true
        assert request.resource_type == "document"

        # expect(request.headers()['user-agent']).toBeTruthy();
        # expect(request.frame() === page.mainFrame()).toBe(true);
        # expect(request.frame().url()).toBe('about:blank');

        Route.continue(route)
        send(this, :intercepted)
      end)

      response = Page.goto(page, assets.prefix <> "/empty.html")
      assert Response.ok(response)

      assert_received(:intercepted)
    end
  end
end
