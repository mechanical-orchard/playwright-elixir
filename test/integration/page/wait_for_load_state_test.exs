defmodule Test.Page.WaitForLoadStateTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page.wait_for_load_state/3" do
    # test "picks up ongoing navigation", %{assets: assets, page: page} do
    #   Page.route(page, "**/one-style.css", fn (route, request) ->
    #     # ...
    #   end)
    # end

    # test "respects timeout", %{assets: assets, page: page} do
    #   this = self()
    # end

    # not yet actually implemented (though the test passes)
    @tag :skip
    test "resolves immediately if loaded", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/one-style.html")
      Page.wait_for_load_state(page)
      assert true
    end
  end
end
