defmodule Playwright.APIResponseTest do
  use Playwright.TestCase, async: true
  alias Playwright.APIRequest
  alias Playwright.APIResponse
  alias Playwright.APIRequestContext

  describe "APIResponse.dispose/" do
    test "on success, causes subsequent usage of `APIResponse` to fail", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

      assert :ok = APIResponse.dispose(response)
      assert {:error, %{type: "ResponseError", message: "Response has been disposed"}} = APIResponse.body(response)
    end
  end
end
