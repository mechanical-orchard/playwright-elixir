defmodule Playwright.APIRequestContextTest do
  use Playwright.TestCase, async: true
  alias Playwright.API.Error
  alias Playwright.APIRequest
  alias Playwright.APIResponse
  alias Playwright.APIRequestContext

  describe "APIRequestContext.delete/3" do
    test "on success, returns `APIResponse` w/ success status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.delete(context, assets.prefix <> "/simple.json")

      assert APIResponse.ok(response)
      assert status == 200
    end

    test "on 404, returns `APIResponse` w/ error status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.delete(context, assets.prefix <> "/bogus.json")

      refute APIResponse.ok(response)
      assert status == 404
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      # fail: out-of-range timeout
      options = %{timeout: -1}
      assert {:error, %Error{type: "RangeError"}} = APIRequestContext.delete(context, assets.prefix <> "/simple.json", options)
    end
  end

  describe "APIRequestContext.delete!/3" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        # fail: out-of-range timeout
        options = %{timeout: -1}
        APIRequestContext.delete!(context, assets.prefix <> "/simple.json", options)
      end
    end
  end

  describe "APIRequestContext.dispose/2" do
    test "on success, invalidates subsequent use related `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(context, assets.prefix <> "/simple.json")

      assert :ok = APIRequestContext.dispose(context)
      assert {:error, %{type: "TargetClosedError"}} = APIResponse.body(response)
    end

    test "on failure, returns `{:error, error}`", %{session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      context = %{context | guid: "bogus"}
      assert {:error, %Error{type: "TargetClosedError"}} = APIRequestContext.dispose(context)
    end

    test "succeeds when provided a 'reason'", %{session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      assert :ok = APIRequestContext.dispose(context, %{reason: "Done!"})
    end
  end

  describe "APIRequestContext.dispose!/2" do
    test "on failure, raises", %{session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        context = %{context | guid: "bogus"}
        APIRequestContext.dispose!(context)
      end
    end
  end

  describe "APIRequestContext.fetch/3" do
    test "on success, returns `APIResponse` for each HTTP method", %{assets: assets, session: session} do
      methods = [:delete, :get, :head, :patch, :post, :put]

      Enum.map(methods, fn method ->
        context = Playwright.request(session) |> APIRequest.new_context()
        response = APIRequestContext.fetch(context, assets.prefix <> "/simple.json", %{method: method})

        assert APIResponse.ok(response)
        assert APIResponse.header(response, "x-playwright-request-method") == String.upcase(Atom.to_string(method))
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

    test "defaults the HTTP request method to 'GET'", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(context, assets.prefix <> "/simple.json")

      assert APIResponse.ok(response)
      assert APIResponse.header(response, "x-playwright-request-method") == "GET"
    end

    test "on 404, returns `APIResponse` w/ error status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.fetch(context, assets.prefix <> "/bogus.json")

      refute APIResponse.ok(response)
      assert status == 404
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      # fail: out-of-range timeout
      options = %{timeout: -1}
      assert {:error, %Error{type: "RangeError"}} = APIRequestContext.fetch(context, assets.prefix <> "/simple.json", options)
    end
  end

  describe "APIRequestContext.fetch!/3" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        # fail: out-of-range timeout
        options = %{timeout: -1}
        APIRequestContext.fetch!(context, assets.prefix <> "/simple.json", options)
      end
    end
  end

  describe "APIRequestContext.get/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.get(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end

    test "on 404, returns `APIResponse` w/ error status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.get(context, assets.prefix <> "/bogus.json")

      refute APIResponse.ok(response)
      assert status == 404
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      # fail: out-of-range timeout
      options = %{timeout: -1}
      assert {:error, %Error{type: "RangeError"}} = APIRequestContext.get(context, assets.prefix <> "/simple.json", options)
    end
  end

  describe "APIRequestContext.get!/3" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        # fail: out-of-range timeout
        options = %{timeout: -1}
        APIRequestContext.get!(context, assets.prefix <> "/simple.json", options)
      end
    end
  end

  describe "APIRequestContext.head/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.head(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end

    test "on 404, returns `APIResponse` w/ error status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.head(context, assets.prefix <> "/bogus.json")

      refute APIResponse.ok(response)
      assert status == 404
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      # fail: out-of-range timeout
      options = %{timeout: -1}
      assert {:error, %Error{type: "RangeError"}} = APIRequestContext.head(context, assets.prefix <> "/simple.json", options)
    end
  end

  describe "APIRequestContext.head!/3" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        # fail: out-of-range timeout
        options = %{timeout: -1}
        APIRequestContext.head!(context, assets.prefix <> "/simple.json", options)
      end
    end
  end

  describe "APIRequestContext.patch/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.patch(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end

    test "on 404, returns `APIResponse` w/ error status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.patch(context, assets.prefix <> "/bogus.json")

      refute APIResponse.ok(response)
      assert status == 404
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      # fail: out-of-range timeout
      options = %{timeout: -1}
      assert {:error, %Error{type: "RangeError"}} = APIRequestContext.patch(context, assets.prefix <> "/simple.json", options)
    end
  end

  describe "APIRequestContext.patch!/3" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        # fail: out-of-range timeout
        options = %{timeout: -1}
        APIRequestContext.patch!(context, assets.prefix <> "/simple.json", options)
      end
    end
  end

  describe "APIRequestContext.post/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.post(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end

    test "on 404, returns `APIResponse` w/ error status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.post(context, assets.prefix <> "/bogus.json")

      refute APIResponse.ok(response)
      assert status == 404
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      # fail: out-of-range timeout
      options = %{timeout: -1}
      assert {:error, %Error{type: "RangeError"}} = APIRequestContext.post(context, assets.prefix <> "/simple.json", options)
    end
  end

  describe "APIRequestContext.post!/3" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        # fail: out-of-range timeout
        options = %{timeout: -1}
        APIRequestContext.post!(context, assets.prefix <> "/simple.json", options)
      end
    end
  end

  describe "APIRequestContext.put/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.put(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end

    test "on 404, returns `APIResponse` w/ error status", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      %APIResponse{status: status} = response = APIRequestContext.put(context, assets.prefix <> "/bogus.json")

      refute APIResponse.ok(response)
      assert status == 404
    end

    test "on failure, returns `{:error, error}`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      # fail: out-of-range timeout
      options = %{timeout: -1}
      assert {:error, %Error{type: "RangeError"}} = APIRequestContext.put(context, assets.prefix <> "/simple.json", options)
    end
  end

  describe "APIRequestContext.put!/3" do
    test "on failure, raises", %{assets: assets, session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        # fail: out-of-range timeout
        options = %{timeout: -1}
        APIRequestContext.put!(context, assets.prefix <> "/simple.json", options)
      end
    end
  end

  describe "APIRequestContext.storage_state/2" do
    test "(WIP) on success, ...", %{session: session} do
      slug = DateTime.utc_now() |> DateTime.to_unix()
      path = "storage-state-#{slug}.json"

      storage = %{
        cookies: [
          %{
            name: "cookie name",
            value: "cookie value",
            domain: "example.com",
            path: "/",
            expires: -1,
            httpOnly: false,
            secure: false,
            sameSite: "Lax"
          }
        ],
        origins: []
      }

      request = Playwright.request(session)
      context = APIRequest.new_context(request, %{storage_state: storage})

      assert ^storage = APIRequestContext.storage_state(context, %{path: path})
      assert(File.exists?(path))
      assert(Jason.decode!(File.read!(path)))

      context = APIRequest.new_context(request, %{storage_state: path})
      assert ^storage = APIRequestContext.storage_state(context, %{path: path})

      File.rm!(path)
    end

    test "on failure, returns `{:error, error}`", %{session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      context = %{context | guid: "bogus"}
      assert {:error, %Error{type: "TargetClosedError"}} = APIRequestContext.storage_state(context)
    end
  end

  describe "APIRequestContext.storage_state!/2" do
    test "on failure, raises", %{session: session} do
      assert_raise RuntimeError, fn ->
        context = Playwright.request(session) |> APIRequest.new_context()
        context = %{context | guid: "bogus"}
        APIRequestContext.storage_state!(context)
      end
    end
  end
end
