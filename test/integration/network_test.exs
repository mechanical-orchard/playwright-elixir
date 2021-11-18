defmodule Playwright.Page.NetworkTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page network events" do
    test "events are fired in the proper order", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "request", fn %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.on(page, "response", fn %{params: %{response: response}} ->
        send(pid, {:response, response.url})
      end)

      Page.on(page, "requestFinished", fn %{params: %{request: request}} ->
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

      Page.on(page, "request", fn %{params: %{page: page}} ->
        send(pid, {:request, page})
      end)

      Page.on(page, "response", fn %{params: %{page: page}} ->
        send(pid, {:response, page})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, %Page{}})
      assert_next_receive({:response, %Page{}})
    end

    test "request finished event", %{assets: assets, page: page} do
      url = assets.empty

      event_info =
        Page.expect_event(page, "requestFinished", fn ->
          Page.goto(page, url)
        end)

      response = event_info.params.response
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
