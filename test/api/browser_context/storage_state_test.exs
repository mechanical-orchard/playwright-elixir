defmodule Playwright.BrowserContext.StorageStateTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Page}

  describe "BrowserContext.storage_state/1" do
    test "returns cookies and origins", %{page: page} do
      context = Page.context(page)

      # Set a cookie via the context
      BrowserContext.add_cookies(context, [
        %{name: "test_cookie", value: "cookie_value", url: "https://example.com"}
      ])

      state = BrowserContext.storage_state(context)

      assert is_map(state)
      # The state should have cookies and origins keys (as atoms or strings)
      cookies = Map.get(state, :cookies) || Map.get(state, "cookies")
      origins = Map.get(state, :origins) || Map.get(state, "origins")

      assert is_list(cookies)
      assert is_list(origins)

      # Verify our cookie is present
      assert Enum.any?(cookies, fn cookie ->
               name = Map.get(cookie, :name) || Map.get(cookie, "name")
               name == "test_cookie"
             end)
    end

    test "returns empty state for fresh context", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)

      state = BrowserContext.storage_state(context)

      assert is_map(state)
      cookies = Map.get(state, :cookies) || Map.get(state, "cookies")
      assert is_list(cookies)

      BrowserContext.close(context)
    end

    test "captures localStorage", %{assets: assets, page: page} do
      context = Page.context(page)

      # Navigate to a real page and set localStorage
      Page.goto(page, assets.empty)
      Page.evaluate(page, "() => localStorage.setItem('test_key', 'test_value')")

      state = BrowserContext.storage_state(context)

      origins = Map.get(state, :origins) || Map.get(state, "origins")
      assert is_list(origins)

      # Find the origin with our localStorage
      origin_with_storage =
        Enum.find(origins, fn origin ->
          local_storage = Map.get(origin, :localStorage) || Map.get(origin, "localStorage")
          is_list(local_storage) && local_storage != []
        end)

      assert origin_with_storage != nil
    end
  end

  describe "BrowserContext.storage_state/2 with path option" do
    test "saves state to JSON file", %{page: page} do
      context = Page.context(page)

      BrowserContext.add_cookies(context, [
        %{name: "file_test", value: "file_value", url: "https://example.com"}
      ])

      path = Path.join(System.tmp_dir!(), "storage_state_#{:rand.uniform(100_000)}.json")

      state = BrowserContext.storage_state(context, path: path)

      # Should still return the state
      assert is_map(state)

      # File should exist
      assert File.exists?(path)

      # File should contain valid JSON
      file_content = File.read!(path)
      decoded = Jason.decode!(file_content)

      assert is_map(decoded)
      assert is_list(decoded["cookies"])

      # Cleanup
      File.rm!(path)
    end
  end

  describe "storageState with indexedDB" do
    @tag exclude: [:page]
    test "accepts indexed_db option", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      state = BrowserContext.storage_state(context, indexed_db: true)
      assert is_map(state)
      BrowserContext.close(context)
    end
  end
end
