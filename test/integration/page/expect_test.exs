defmodule Playwright.Page.NetworkTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page, Response}
  alias Playwright.SDK.Channel.{Error, Event}

  describe "Page.expect_event/3 without a 'trigger" do
    test "w/ an event", %{assets: assets, page: page} do
      url = assets.empty

      Task.start(fn -> Page.goto(page, url) end)
      %Event{params: params} = Page.expect_event(page, :request_finished)

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a (truthy) predicate", %{assets: assets, page: page} do
      url = assets.empty

      Task.start(fn -> Page.goto(page, url) end)

      %Event{params: params} =
        Page.expect_event(page, :request_finished, %{
          predicate: fn owner, e ->
            %BrowserContext{} = owner
            %Event{} = e
            true
          end
        })

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a timeout", %{page: page} do
      {:error, %Error{message: message}} =
        Page.expect_event(page, :request_finished, %{
          timeout: 200
        })

      assert message == "Timeout 200ms exceeded."
    end

    test "w/ an event, a (truthy) predicate, and a timeout", %{assets: assets, page: page} do
      Task.start(fn -> Page.goto(page, assets.empty) end)

      event =
        Page.expect_event(page, :request_finished, %{
          predicate: fn _, _ ->
            true
          end,
          timeout: 200
        })

      assert event.type == :request_finished
    end

    test "w/ an event, a (falsy) predicate, and (incidentally) a timeout", %{assets: assets, page: page} do
      Task.start(fn -> Page.goto(page, assets.empty) end)

      {:error, %Error{message: message}} =
        Page.expect_event(page, :request_finished, %{
          predicate: fn _, _ ->
            false
          end,
          timeout: 200
        })

      assert message == "Timeout 200ms exceeded."
    end
  end

  describe "Page.expect_event/3 with a 'trigger" do
    test "w/ an event and a trigger", %{assets: assets, page: page} do
      url = assets.empty

      %Event{params: params} =
        Page.expect_event(page, :request_finished, fn ->
          Page.goto(page, url)
        end)

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a (truthy) predicate", %{assets: assets, page: page} do
      url = assets.empty

      %Event{params: params} =
        Page.expect_event(
          page,
          :request_finished,
          %{
            predicate: fn _, _ -> true end
          },
          fn ->
            Page.goto(page, url)
          end
        )

      response = params.response
      assert Response.ok(response)
      assert response.url == url
    end

    test "w/ an event and a (falsy) predicate", %{assets: assets, page: page} do
      {:error, %Error{message: message}} =
        Page.expect_event(
          page,
          :request_finished,
          %{
            predicate: fn _, _ ->
              false
            end,
            timeout: 200
          },
          fn ->
            Page.goto(page, assets.empty)
          end
        )

      assert message == "Timeout 200ms exceeded."
    end

    test "w/ an event and a timeout", %{assets: assets, page: page} do
      %Event{params: params} =
        Page.expect_event(
          page,
          :request_finished,
          %{
            timeout: 200
          },
          fn ->
            Page.goto(page, assets.empty)
          end
        )

      assert Response.ok(params.response)
    end
  end
end
