defmodule Playwright.WIPTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Page}

  describe "WIP" do
    test "...A", %{assets: assets, page: page} do
      pid = self()
      url = assets.empty

      Page.on(page, "requestFinished", fn _x, %{params: %{request: request}} ->
        send(pid, {:finished, request.url})
      end)

      %{response: response} = Page.expect_event(page, "requestFinished", fn _x ->
        Page.goto(page, url)
      end)

      assert response.url == url
      assert_next_receive({:finished, ^url})
    end
  end

  # test "...B", %{assets: assets, page: page} do
  #     pid = self()
  #     url = assets.empty

  #     Page.on(page, "requestFinished", fn _x, %{params: %{request: request}} ->
  #       send(pid, {:finished, request.url})
  #     end)

  #     Page.expect_event(page, "requestFinished")
  #     Page.goto(page, url)

  #     assert_next_receive({:finished, ^url})
  #     # timeout if expected event not fired.
  #   end
  # end
end
