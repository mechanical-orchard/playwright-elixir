defmodule Playwright.APIRequestContextTest do
  use Playwright.TestCase, async: true
  alias Playwright.APIRequest
  alias Playwright.APIResponse
  alias Playwright.APIRequestContext

  describe "APIRequestContext.delete/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.delete(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end
  end

  describe "APIRequestContext.dispose/2" do
    test "on success, invalidates subsequent use related `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.fetch(context, assets.prefix <> "/simple.json")

      assert :ok = APIRequestContext.dispose(context)
      assert {:error, %{type: "TargetClosedError"}} = APIResponse.body(response)
    end

    test "succeeds when provided a 'reason'", %{session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      assert :ok = APIRequestContext.dispose(context, %{reason: "Done!"})
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
  end

  describe "APIRequestContext.get/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.get(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end
  end

  describe "APIRequestContext.head/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.head(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end
  end

  describe "APIRequestContext.patch/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.patch(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end
  end

  describe "APIRequestContext.post/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.post(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end
  end

  describe "APIRequestContext.put/3" do
    test "on success, returns `APIResponse`", %{assets: assets, session: session} do
      context = Playwright.request(session) |> APIRequest.new_context()
      response = APIRequestContext.put(context, assets.prefix <> "/simple.json")
      assert APIResponse.ok(response)
    end
  end

  describe "APIRequestContext.storage_state/2" do
    test "(WIP) on success, ...", %{session: session} do
      # python: test_storage_state_should_round_trip_through_file
      # ---
      context =
        Playwright.request(session)
        |> APIRequest.new_context(%{
          storage_state: %{
            cookies: [
              %{
                name: "cookie name",
                value: "cookie value",
                domain: "example.com",
                path: "/",
                expires: -1,
                http_only: false,
                secure: false,
                same_site: "Lax"
              }
            ],
            origins: []
          }
        })

      assert [
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
             ] = APIRequestContext.storage_state(context)
    end
  end
end
