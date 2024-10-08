defmodule Page.ScreenshotTest do
  use Playwright.TestCase, async: true
  require Logger
  alias Playwright.Page

  # NOTE: in addition to the explicit assertions made by these tests, we're also
  # demonstrating a couple other capabilities/quirks:
  #
  # - Given the frame data size for a screenshot is (almost certainly) larger
  #   than 32K bytes, these test cover handling of multi-message frames.
  # - The fact that we do not reassign `page` after the `Page.goto` calls in
  #   these tests shows that there is state managed by the Playwright browser
  #   server (in the form of an open web page) that can be addressed by way
  #   of the static `Page.guid` that we hold in local state. Whether or not that
  #   is a good idea is left to the imagination of the consumer.
  describe "screenshot/2" do
    test "caputures a screenshot, returning the base64 encoded binary", %{page: page} do
      case Page.goto(page, "https://playwright.dev", %{timeout: 5000}) do
        {:error, error} ->
          Logger.warning("Unabled to reach 'https://playwright.dev' for screenshot test: #{inspect(error)}")

        _ ->
          max_frame_size = 32_768
          raw = Page.screenshot(page, %{full_page: true, type: "png"})
          assert byte_size(raw) > max_frame_size
      end
    end

    test "caputures a screenshot, optionally writing the result to local disk", %{page: page} do
      slug = DateTime.utc_now() |> DateTime.to_unix()
      path = "screenshot-#{slug}.png"

      refute(File.exists?(path))

      case Page.goto(page, "https://playwright.dev", %{timeout: 5000}) do
        {:error, error} ->
          Logger.warning("Unabled to reach 'https://playwright.dev' for screenshot test: #{inspect(error)}")

        _ ->
          Page.screenshot(page, %{
            full_page: true,
            path: path
          })

          assert(File.exists?(path))
          File.rm!(path)
      end
    end
  end
end
