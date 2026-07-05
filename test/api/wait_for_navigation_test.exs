defmodule Playwright.WaitForNavigationTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Frame, Page}

  describe "Frame.wait_for_navigation/3" do
    test "waits for navigation triggered by click", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<a href="#{assets.empty}">link</a>|)
      frame = Page.main_frame(page)

      result =
        Frame.wait_for_navigation(frame, fn ->
          Page.click(page, "a")
        end)

      assert %Frame{} = result
      assert String.ends_with?(Frame.url(result), "/empty.html")
    end

    test "waits with URL glob pattern", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<a href="#{assets.empty}">link</a>|)
      frame = Page.main_frame(page)

      result =
        Frame.wait_for_navigation(frame, %{url: "**/empty.html"}, fn ->
          Page.click(page, "a")
        end)

      assert %Frame{} = result
    end

    test "waits with regex URL pattern", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<a href="#{assets.empty}">link</a>|)
      frame = Page.main_frame(page)

      result =
        Frame.wait_for_navigation(frame, %{url: ~r/empty\.html$/}, fn ->
          Page.click(page, "a")
        end)

      assert %Frame{} = result
    end

    test "waits with function predicate", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<a href="#{assets.empty}">link</a>|)
      frame = Page.main_frame(page)

      result =
        Frame.wait_for_navigation(frame, %{url: fn url -> String.contains?(url, "empty") end}, fn ->
          Page.click(page, "a")
        end)

      assert %Frame{} = result
    end

    test "times out when no navigation occurs", %{page: page} do
      Page.set_content(page, "<div>no links</div>")
      frame = Page.main_frame(page)

      result =
        Frame.wait_for_navigation(frame, %{timeout: 100}, fn ->
          # Do nothing that would trigger navigation
          :ok
        end)

      assert {:error, _} = result
    end

    test "respects wait_until option", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<a href="#{assets.empty}">link</a>|)
      frame = Page.main_frame(page)

      result =
        Frame.wait_for_navigation(frame, %{wait_until: "domcontentloaded"}, fn ->
          Page.click(page, "a")
        end)

      assert %Frame{} = result
    end

    test "works with goto navigation", %{assets: assets, page: page} do
      frame = Page.main_frame(page)

      result =
        Frame.wait_for_navigation(frame, fn ->
          Page.goto(page, assets.empty)
        end)

      assert %Frame{} = result
      assert String.ends_with?(Frame.url(result), "/empty.html")
    end
  end

  describe "Page.wait_for_navigation/3" do
    test "waits for navigation and returns page", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<a href="#{assets.empty}">link</a>|)

      result =
        Page.wait_for_navigation(page, fn ->
          Page.click(page, "a")
        end)

      assert %Page{} = result
      assert String.ends_with?(Page.url(result), "/empty.html")
    end

    test "waits with URL pattern", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<a href="#{assets.empty}">link</a>|)

      result =
        Page.wait_for_navigation(page, %{url: "**/empty.html"}, fn ->
          Page.click(page, "a")
        end)

      assert %Page{} = result
    end

    test "times out when no navigation occurs", %{page: page} do
      Page.set_content(page, "<div>no links</div>")

      result =
        Page.wait_for_navigation(page, %{timeout: 100}, fn ->
          :ok
        end)

      assert {:error, _} = result
    end
  end
end
