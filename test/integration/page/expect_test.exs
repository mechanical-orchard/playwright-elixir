defmodule Playwright.Page.NetworkTest do
  use Playwright.TestCase
  alias Playwright.{Page, Response}

  describe "Page.expect_*/*" do
    test "Page.expect_event/3 with :request_finished", %{assets: assets, page: page} do
      url = assets.empty

      event_info =
        Page.expect_event(page, :request_finished, fn ->
          Page.goto(page, url)
        end)

      response = event_info.params.response
      assert Response.ok(response)
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
