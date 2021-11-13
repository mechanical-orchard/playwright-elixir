defmodule Playwright.Page.NetworkTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

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

      Page.on(page, "requestFinished", fn _, %{params: %{request: request}} ->
        send(pid, {:finished, request.url})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, ^url})
      assert_next_receive({:response, ^url})
      assert_next_receive({:finished, ^url})
    end
  end
end
