defmodule Test.Features.ElementHandle.ContentFrameTest do
  use Playwright.TestCase

  # alias Playwright.ElementHandle
  alias Playwright.JSHandle
  alias Playwright.Page

  describe "ElementHandle.content_frame/1" do
    @tag :skip
    test "...", %{assets: assets, page: page} do
      empty_page = assets.prefix <> "/empty.html"
      Page.goto(page, empty_page)

      attach_frame(page, "frame1", empty_page)
      handle = Page.query_selector(page, "#frame1")

      require Logger
      Logger.info("handle: #{inspect(handle)}")

      assert handle == "lala"
      # assert length(Page.frames(page)) == 2
    end
  end

  defp attach_frame(%Playwright.Page{} = page, frame_id, url) do
    handle =
      Page.evaluate_handle(
        page,
        """
        async ({frame_id, url}) => {
          const frame = document.createElement('iframe');
                frame.src = url;
                frame.id = frame_id;
          document.body.appendChild(frame);
          await new Promise(x => frame.onload = x);
          return frame;
        }
        """,
        %{"frame_id" => frame_id, "url" => url}
      )

    {handle, JSHandle.as_element(handle)}
  end
end
