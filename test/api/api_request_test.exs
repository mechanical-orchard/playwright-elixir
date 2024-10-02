defmodule Playwright.APIRequestTest do
  use Playwright.TestCase, async: true
  alias Playwright.APIRequest
  alias Playwright.APIRequestContext

  describe "APIRequest.new_context/2" do
    test "on success, returns a new `APIRequestContext`", %{session: session} do
      request = Playwright.request(session)
      assert %APIRequestContext{} = APIRequest.new_context(request)
    end

    test "on failure w/out options, returns an error tuple", %{session: session} do
      request = Playwright.request(session)
      # to force an error...
      request = %{request | guid: "Bogus"}
      assert {:error, _} = APIRequest.new_context(request)
    end

    test "on failure with options, returns an error tuple", %{session: session} do
      request = Playwright.request(session)
      # to force an error...
      request = %{request | guid: "Bogus"}
      assert {:error, _} = APIRequest.new_context(request, %{})
    end
  end

  describe "BrowserContext.new_context!/2" do
    test "on success, returns 'subject", %{session: session} do
      request = Playwright.request(session)
      assert %APIRequestContext{} = APIRequest.new_context!(request)
    end

    test "on failure w/out `options`, raises `RuntimeError`", %{session: session} do
      assert_raise RuntimeError, fn ->
        request = Playwright.request(session)
        # to force an error...
        request = %{request | guid: "Bogus"}
        APIRequest.new_context!(request)
      end
    end

    test "on failure with `options`, raises `RuntimeError`", %{session: session} do
      assert_raise RuntimeError, fn ->
        request = Playwright.request(session)
        # to force an error...
        request = %{request | guid: "Bogus"}
        APIRequest.new_context!(request, %{})
      end
    end
  end
end
