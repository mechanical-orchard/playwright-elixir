defmodule Playwright.WaitForNetworkTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Page, Request, Response}

  describe "wait_for_request/4" do
    test "waits for request matching glob pattern", %{page: page, assets: assets} do
      request =
        Page.wait_for_request(page, "**/empty.html", %{}, fn ->
          Page.goto(page, assets.empty)
        end)

      assert %Request{} = request
      assert request.url =~ "empty.html"
    end

    test "waits for request matching regex", %{page: page, assets: assets} do
      request =
        Page.wait_for_request(page, ~r/empty\.html$/, %{}, fn ->
          Page.goto(page, assets.empty)
        end)

      assert %Request{} = request
      assert String.ends_with?(request.url, "empty.html")
    end

    test "waits for request matching predicate function", %{page: page, assets: assets} do
      request =
        Page.wait_for_request(
          page,
          fn req -> req.method == "GET" and String.contains?(req.url, "empty") end,
          %{},
          fn -> Page.goto(page, assets.empty) end
        )

      assert %Request{} = request
      assert request.method == "GET"
    end

    test "times out when no matching request", %{page: page} do
      result = Page.wait_for_request(page, "**/nonexistent-path-12345", %{timeout: 500})

      assert {:error, _} = result
    end
  end

  describe "wait_for_response/4" do
    test "waits for response matching glob pattern", %{page: page, assets: assets} do
      response =
        Page.wait_for_response(page, "**/empty.html", %{}, fn ->
          Page.goto(page, assets.empty)
        end)

      assert %Response{} = response
      assert response.url =~ "empty.html"
      assert response.status == 200
    end

    test "waits for response matching regex", %{page: page, assets: assets} do
      response =
        Page.wait_for_response(page, ~r/empty\.html$/, %{}, fn ->
          Page.goto(page, assets.empty)
        end)

      assert %Response{} = response
      assert String.ends_with?(response.url, "empty.html")
    end

    test "waits for response matching predicate checking status", %{page: page, assets: assets} do
      response =
        Page.wait_for_response(
          page,
          fn resp -> resp.status == 200 and String.contains?(resp.url, "empty") end,
          %{},
          fn -> Page.goto(page, assets.empty) end
        )

      assert %Response{} = response
      assert response.status == 200
    end

    test "times out when no matching response", %{page: page} do
      result = Page.wait_for_response(page, "**/nonexistent-path-12345", %{timeout: 500})

      assert {:error, _} = result
    end

    test "can access response body after waiting", %{page: page, assets: assets} do
      response =
        Page.wait_for_response(page, "**/dom.html", %{}, fn ->
          Page.goto(page, assets.dom)
        end)

      assert %Response{} = response
      body = Response.text(response)
      assert is_binary(body)
      assert String.length(body) > 0
    end
  end
end
