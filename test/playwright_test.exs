defmodule Playwright.PlaywrightTest do
  use ExUnit.Case
  use Playwright.UnitTest
  alias Playwright.API.{Browser, Page}

  describe "Playwright.connect/2" do
    @tag :ws
    test "with :chromium" do
      with {:ok, br} <- Playwright.connect(:chromium),
           {:ok, pg} <- Browser.new_page(br),
           {:ok, rs} <- Page.goto(pg, "https://www.whatsmybrowser.org") do
        assert Playwright.Response.ok(rs)
        assert Playwright.Page.text_content(pg, "h2.header") =~ "Chrome"
      end
      |> pass()
    end

    @tag :ws
    test "with :firefox" do
      with {:ok, br} <- Playwright.connect(:firefox),
           {:ok, pg} <- Browser.new_page(br),
           {:ok, rs} <- Page.goto(pg, "https://www.whatsmybrowser.org") do
        assert Playwright.Response.ok(rs)
        assert Playwright.Page.text_content(pg, "h2.header") =~ "Firefox"
      end
      |> pass()
    end

    @tag :ws
    test "with :webkit" do
      with {:ok, br} <- Playwright.connect(:webkit),
           {:ok, pg} <- Browser.new_page(br),
           {:ok, rs} <- Page.goto(pg, "https://www.whatsmybrowser.org") do
        assert Playwright.Response.ok(rs)
        assert Playwright.Page.text_content(pg, "h2.header") =~ "Safari"
      end
      |> pass()
    end
  end

  describe "Playwright.launch/2" do
    test "with :chromium" do
      with {:ok, br} <- Playwright.launch(:chromium),
           {:ok, pg} <- Browser.new_page(br),
           {:ok, rs} <- Page.goto(pg, "https://www.whatsmybrowser.org") do
        assert Playwright.Response.ok(rs)
        assert Playwright.Page.text_content(pg, "h2.header") =~ "Chrome"
      end
      |> pass()
    end

    test "with :firefox" do
      with {:ok, br} <- Playwright.launch(:firefox),
           {:ok, pg} <- Browser.new_page(br),
           {:ok, rs} <- Page.goto(pg, "https://www.whatsmybrowser.org") do
        assert Playwright.Response.ok(rs)
        assert Playwright.Page.text_content(pg, "h2.header") =~ "Firefox"
      end
      |> pass()
    end

    test "with :webkit" do
      with {:ok, br} <- Playwright.launch(:webkit),
           {:ok, pg} <- Browser.new_page(br),
           {:ok, rs} <- Page.goto(pg, "https://www.whatsmybrowser.org") do
        assert Playwright.Response.ok(rs)
        assert Playwright.Page.text_content(pg, "h2.header") =~ "Safari"
      end
      |> pass()
    end

    @tag :headed
    test "with options: `%{headless: false}`" do
      with {:ok, br} <- Playwright.launch(:chromium, %{headless: false}),
           {:ok, pg} <- Browser.new_page(br),
           {:ok, rs} <- Page.goto(pg, "https://www.whatsmybrowser.org") do
        assert Playwright.Response.ok(rs)
        assert Playwright.Page.text_content(pg, "h2.header") =~ "Chrome"
      end
      |> pass()
    end
  end
end
