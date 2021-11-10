defmodule Playwright.Page.EventsTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page

  require Logger

  describe "Page network events" do
    test "events are fired in the proper order", %{assets: assets, page: page} do
      this = self()
      expected_url = assets.prefix <> "/empty.html"

      Page.on(page, "request", fn (_, %{params: %{request: request}}) ->
        send(this, {:request, request.url})
      end)
      Page.on(page, "response", fn (_, %{params: %{response: response}}) ->
        send(this, {:response, response.url})
      end)
      Page.on(page, "requestFinished", fn (_, %{params: %{request: request}}) ->
        send(this, {:finished, request.url})
      end)

      Page.goto(page, expected_url)

      # NOTE: these checks are not in fact enforcing order.
      assert_received({:request, ^expected_url})
      assert_received({:response, ^expected_url})
      assert_received({:finished, ^expected_url})
    end

    test "'request' event fires for navigation requests", %{assets: assets, page: page} do
      this = self()
      expected_url = assets.prefix <> "/empty.html"

      Page.on(page, "request", fn (_, %{params: %{request: request}}) ->
        send(this, request.url)
      end)

      Page.goto(page, expected_url)
      assert_received(^expected_url)
    end
  end
end
