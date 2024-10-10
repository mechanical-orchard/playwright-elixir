defmodule Playwright.APIResponseTest do
  use Playwright.TestCase, async: true
  alias Playwright.API.Error
  alias Playwright.APIRequest
  alias Playwright.APIResponse
  alias Playwright.APIRequestContext

  describe "APIResponse.body/1" do
    test "on success, returns response body", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

      assert "{\"foo\": \"bar\"}\n" = APIResponse.body(response)
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")
      response = %{response | fetchUid: "bogus"}

      assert {:error, %Error{type: "ResponseError"}} = APIResponse.body(response)
    end

    test "on HTTP error, returns status code as the response body", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/bogus.json")

      assert "404" = APIResponse.body(response)
    end
  end

  describe "APIResponse.body!/1" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        request = Playwright.request(session) |> APIRequest.new_context()
        response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")
        response = %{response | fetchUid: "bogus"}

        APIResponse.body!(response)
      end
    end
  end

  describe "APIResponse.dispose/1" do
    test "on success, causes subsequent usage of `APIResponse` to fail", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

      assert :ok = APIResponse.dispose(response)
      assert {:error, %{type: "ResponseError", message: "Response has been disposed"}} = APIResponse.body(response)
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")
      response = %{response | context: %{guid: "bogus", session: session}}

      assert {:error, %Error{type: "TargetClosedError"}} = APIResponse.dispose(response)
    end
  end

  describe "APIResponse.dispose!/1" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        request = Playwright.request(session) |> APIRequest.new_context()
        response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")
        response = %{response | context: %{guid: "bogus", session: session}}

        APIResponse.dispose!(response)
      end
    end
  end

  describe "APIResponse.header/1" do
    test "on success, returns the value of the HTTP header", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

      assert "application/json" = APIResponse.header(response, "content-type")
    end

    test "when the HTTP header is not found, returns `nil`", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

      assert APIResponse.header(response, "bogus") == nil
    end
  end

  describe "APIResponse.headers/1" do
    test "returns the response headers as a `map(name => value)`", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

      assert %{
               "connection" => "close",
               "content-length" => "15",
               "content-type" => "application/json",
               "x-playwright-request-method" => "GET"
             } = APIResponse.headers(response)
    end
  end

  describe "APIResponse.json/1" do
    test "on success, returns response body", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")

      assert %{"foo" => "bar"} = APIResponse.json(response)
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")
      response = %{response | fetchUid: "bogus"}

      assert {:error, %Error{type: "ResponseError"}} = APIResponse.json(response)
    end

    test "on HTTP error, returns status code as the response body", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/bogus.json")

      assert 404 = APIResponse.json(response)
    end
  end

  describe "APIResponse.json!/1" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        request = Playwright.request(session) |> APIRequest.new_context()
        response = APIRequestContext.fetch(request, assets.prefix <> "/simple.json")
        response = %{response | fetchUid: "bogus"}

        APIResponse.json!(response)
      end
    end
  end

  describe "APIResponse.ok/1" do
    test "returns true when the response status code is in the range, 200-299" do
      range = 200..299

      Enum.each(range, fn code ->
        assert APIResponse.ok(%APIResponse{status: code})
      end)
    end

    test "returns true when the response status code is 0" do
      assert APIResponse.ok(%APIResponse{status: 0})
    end

    test "returns false otherwise" do
      range = 1..199

      Enum.each(range, fn code ->
        refute APIResponse.ok(%APIResponse{status: code})
      end)

      range = 300..999

      Enum.each(range, fn code ->
        refute APIResponse.ok(%APIResponse{status: code})
      end)
    end
  end

  describe "APIResponse.text/1" do
    test "on success, returns response body", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/empty.html")

      assert APIResponse.text(response) == ""
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/empty.html")
      response = %{response | fetchUid: "bogus"}

      assert {:error, %Error{type: "ResponseError"}} = APIResponse.text(response)
    end

    test "on HTTP error, returns status code as the response body", %{assets: assets, session: session} do
      request = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(request, assets.prefix <> "/bogus.text")

      assert "404" = APIResponse.text(response)
    end
  end

  describe "APIResponse.text!/1" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        request = Playwright.request(session) |> APIRequest.new_context()
        response = APIRequestContext.fetch(request, assets.prefix <> "/empty.html")
        response = %{response | fetchUid: "bogus"}

        APIResponse.text!(response)
      end
    end
  end
end
