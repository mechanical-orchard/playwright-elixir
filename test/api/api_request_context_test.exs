defmodule Playwright.APIRequestContextTest do
  use Playwright.TestCase, async: true
  alias Playwright.APIResponse
  alias Playwright.APIRequest
  alias Playwright.APIRequestContext

  describe "APIRequestContext.delete/3" do
  end

  describe "APIRequestContext.dispose/2" do
  end

  describe "APIRequestContext.fetch/3" do
    test "on success, returns `APIResponse` for each HTTP method", %{assets: assets, session: session} do
      methods = [:delete, :get, :head, :patch, :post, :put]

      Enum.map(methods, fn method ->
        request = Playwright.request(session) |> APIRequest.new_context()
        response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

        assert APIResponse.ok(response)
        assert APIResponse.header(response, "content-type") == "application/json"
        assert APIResponse.header(response, :"content-type") == "application/json"

        assert response.status == 200
        assert response.statusText == "OK"
        assert response.url == assets.prefix <> "/simple.json"

        unless method === :head do
          assert APIResponse.text(response) == "{\"foo\": \"bar\"}\n"
          assert APIResponse.json(response) == %{"foo" => "bar"}
        end
      end)
    end
  end

  describe "APIRequestContext.get/3" do
  end

  describe "APIRequestContext.head/3" do
  end

  describe "APIRequestContext.patch/3" do
  end

  describe "APIRequestContext.post/3" do
  end

  describe "APIRequestContext.put/3" do
  end

  describe "APIRequestContext.storage_state/2" do
  end
end
