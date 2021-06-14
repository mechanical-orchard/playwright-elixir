defmodule Test.Features.Playwright.Page.ScreenshotTest do
  use Playwright.TestCase

  describe "screenshot/2" do
    test "caputures a screenshot, returning the base64 encoded binary", %{browser: browser} do
      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto("https://playwright.dev")

      raw =
        Playwright.Page.screenshot(page, %{
          "fullPage" => true,
          "type" => "png"
        })

      # NOTE:
      # we'e *also* demonstrating here that the screenshot bytes are composed
      # from multiple received frames.
      max_frame_size = 32_768
      assert byte_size(raw) > max_frame_size

      Playwright.Page.close(page)
    end

    test "caputures a screenshot, optionally writing the result to local disk", %{browser: browser} do
      # uh, "slug"... :p
      slug = DateTime.utc_now() |> DateTime.to_unix()
      path = "screenshot-#{slug}.png"

      refute(File.exists?(path))

      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.goto("https://playwright.dev")

      Playwright.Page.screenshot(page, %{
        "fullPage" => true,
        "path" => path
      })

      assert(File.exists?(path))

      File.rm!(path)
      Playwright.Page.close(page)
    end
  end
end
