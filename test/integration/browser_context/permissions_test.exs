defmodule Playwright.BrowserContext.PermissionsTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Browser, BrowserContext, Page}

  describe "Permissions" do
    test "default to 'prompt'", %{assets: assets, page: page} do
      page |> Page.goto(assets.empty)
      assert get_permission(page, "geolocation") == "prompt"
    end
  end

  describe "BrowserContext.grant_permissions/3" do
    test "denies permission when not listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, [], %{origin: assets.empty})
      assert get_permission(page, "geolocation") == "denied"
    end

    test "errors when a bad permission is given", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      assert {:error, %{message: "Unknown permission: foo"}} =
               BrowserContext.grant_permissions(context, ["foo"], %{origin: assets.empty})
    end

    test "grants geolocation permission when origin is listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"], %{origin: assets.empty})
      assert get_permission(page, "geolocation") == "granted"
    end

    test "prompts for geolocation permission when origin is not listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)
      BrowserContext.grant_permissions(context, ["geolocation"], %{origin: assets.empty})

      page |> Page.goto(String.replace(assets.empty, "localhost", "127.0.0.1"))
      assert get_permission(page, "geolocation") == "prompt"
    end

    test "grants notification permission when listed", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["notifications"], %{origin: assets.empty})
      assert get_permission(page, "notifications") == "granted"
    end

    test "grants permissions when listed for all domains", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      assert get_permission(page, "geolocation") == "granted"
    end

    test "accumulates permissions", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.grant_permissions(context, ["notifications"])

      assert get_permission(page, "geolocation") == "granted"
      assert get_permission(page, "notifications") == "granted"
    end

    @tag exclude: [:page]
    test "grants permissions on `Browser.new_context/1`", %{assets: assets, browser: browser} do
      context = Browser.new_context(browser, %{permissions: ["geolocation"]})
      page = BrowserContext.new_page(context)

      page |> Page.goto(assets.empty)
      assert get_permission(page, "geolocation") == "granted"

      BrowserContext.close(context)
      Page.close(page)
    end
  end

  describe "BrowserContext.clear_permissions/1" do
    test "clears previously granted permissions", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.clear_permissions(context)
      BrowserContext.grant_permissions(context, ["notifications"])

      assert get_permission(page, "geolocation") == "denied"
      assert get_permission(page, "notifications") == "granted"
    end

    test "resets permissions", %{assets: assets, page: page} do
      context = Page.context(page)
      page |> Page.goto(assets.empty)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.clear_permissions(context)
      assert get_permission(page, "geolocation") == "prompt"
    end
  end

  # ---

  defp get_permission(page, name) do
    Page.evaluate(page, "(name) => navigator.permissions.query({name: name}).then(result => result.state)", name)
  end
end
