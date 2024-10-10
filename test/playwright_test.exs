defmodule Playwright.PlaywrightTest do
  use ExUnit.Case, async: true
  use PlaywrightTest.Case
  alias Playwright.{Browser, Page, Response}

  describe "Playwright.connect/2" do
    @tag :ws
    test "with :chromium" do
      with {:ok, browser} <- Playwright.connect(:chromium) do
        page = Browser.new_page(browser)

        assert page
               |> Page.goto("https://www.whatsmybrowser.org")
               |> Response.ok()

        assert Playwright.Page.text_content(page, "h2.header") =~ "Chrome"
      end
    end

    @tag :ws
    test "with :firefox" do
      with {:ok, browser} <- Playwright.connect(:firefox) do
        page = Browser.new_page(browser)

        assert page
               |> Page.goto("https://www.whatsmybrowser.org")
               |> Response.ok()

        assert Playwright.Page.text_content(page, "h2.header") =~ "Firefox"
      end
    end

    @tag :ws
    test "with :webkit" do
      with {:ok, browser} <- Playwright.connect(:webkit) do
        page = Browser.new_page(browser)

        assert page
               |> Page.goto("https://www.whatsmybrowser.org")
               |> Response.ok()

        assert Playwright.Page.text_content(page, "h2.header") =~ "Safari"
      end
    end
  end

  describe "Playwright.launch/2" do
    test "launches and returns an instance of the requested Browser" do
      {:ok, session, browser} = Playwright.launch(:chromium)

      assert is_pid(session)

      assert browser
             |> Browser.new_page()
             |> Page.goto("http://example.com")
             |> Response.ok()
    end
  end

  describe "Playwright.request/1" do
    test "returns an `APIRequest` for the session" do
      {:ok, session, _browser} = Playwright.launch(:chromium)
      assert %Playwright.APIRequest{session: ^session} = Playwright.request(session)
    end
  end

  describe "PlaywrightTest.Case context" do
    test "using `:browser`", %{browser: browser} do
      assert browser
             |> Browser.new_page()
             |> Page.goto("http://example.com")
             |> Response.ok()
    end

    test "using `:page`", %{page: page} do
      assert page
             |> Page.goto("http://example.com")
             |> Response.ok()
    end

    @tag exclude: [:page]
    test "excluding `:page` via `@tag`", context do
      assert Map.has_key?(context, :browser)
      refute Map.has_key?(context, :page)
    end
  end
end
