defmodule Playwright.NetworkTest do
  use Playwright.TestCase
  alias Playwright.Page

  describe "Page network events" do
    test "events are fired in the proper order", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, :request, fn %{params: %{request: request}} ->
        send(pid, {:request, request.url})
      end)

      Page.on(page, :response, fn %{params: %{response: response}} ->
        send(pid, {:response, response.url})
      end)

      Page.on(page, :request_finished, fn %{params: %{request: request}} ->
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

      Page.on(page, :request, fn %{params: %{page: page}} ->
        send(pid, {:request, page})
      end)

      Page.on(page, :response, fn %{params: %{page: page}} ->
        send(pid, {:response, page})
      end)

      Page.goto(page, url)
      assert_next_receive({:request, %Page{}})
      assert_next_receive({:response, %Page{}})
    end
  end
end
