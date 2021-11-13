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
