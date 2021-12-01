defmodule Playwright.Page.WaitForTest do
  use Playwright.TestCase
  # alias Playwright.{Page}

  # describe "Page.wait_for_load_state/3" do
  #   @tag exclude: [:page]
  #   test "waits for load state of new page", %{browser: browser} do
  #     context = Browser.new_context(browser)

  #     %Runner.EventInfo{params: %{page: page}} =
  #       BrowserContext.expect_page(context, fn ->
  #         BrowserContext.new_page(context)
  #       end)

  #     Page.wait_for_load_state(page)
  #     assert Page.evaluate(page, "document.readyState") == "complete"
  #   end

  #   test "on 'networkidle'", %{assets: assets, page: page} do
  #     wait =
  #       Task.async(fn ->
  #         Page.wait_for_load_state(page, "networkidle")
  #       end)

  #     Page.goto(page, assets.prefix <> "/networkidle.html")
  #     Task.await(wait)
  #   end
  # end
end
