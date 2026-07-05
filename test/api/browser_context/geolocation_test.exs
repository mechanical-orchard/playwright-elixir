defmodule Playwright.BrowserContext.GeolocationTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page}

  describe "BrowserContext.set_geolocation/2" do
    test "sets geolocation", %{assets: assets, page: page} do
      context = Page.context(page)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.set_geolocation(context, %{latitude: 37.7749, longitude: -122.4194})

      Page.goto(page, assets.empty)

      # Verify via JavaScript
      result =
        Page.evaluate(page, """
          () => new Promise(resolve => {
            navigator.geolocation.getCurrentPosition(pos => {
              resolve({lat: pos.coords.latitude, lng: pos.coords.longitude});
            });
          })
        """)

      # Handle both atom and string keys
      lat = Map.get(result, :lat) || Map.get(result, "lat")
      lng = Map.get(result, :lng) || Map.get(result, "lng")

      assert lat == 37.7749
      assert lng == -122.4194
    end

    test "sets geolocation with accuracy", %{assets: assets, page: page} do
      context = Page.context(page)

      BrowserContext.grant_permissions(context, ["geolocation"])

      BrowserContext.set_geolocation(context, %{
        latitude: 51.5074,
        longitude: -0.1278,
        accuracy: 100
      })

      Page.goto(page, assets.empty)

      result =
        Page.evaluate(page, """
          () => new Promise(resolve => {
            navigator.geolocation.getCurrentPosition(pos => {
              resolve({accuracy: pos.coords.accuracy});
            });
          })
        """)

      accuracy = Map.get(result, :accuracy) || Map.get(result, "accuracy")
      assert accuracy == 100
    end

    test "updates geolocation", %{assets: assets, page: page} do
      context = Page.context(page)

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.set_geolocation(context, %{latitude: 10, longitude: 10})

      Page.goto(page, assets.empty)

      # Update to new location
      BrowserContext.set_geolocation(context, %{latitude: 20, longitude: 30})

      result =
        Page.evaluate(page, """
          () => new Promise(resolve => {
            navigator.geolocation.getCurrentPosition(pos => {
              resolve({lat: pos.coords.latitude, lng: pos.coords.longitude});
            });
          })
        """)

      lat = Map.get(result, :lat) || Map.get(result, "lat")
      lng = Map.get(result, :lng) || Map.get(result, "lng")

      assert lat == 20
      assert lng == 30
    end
  end
end
