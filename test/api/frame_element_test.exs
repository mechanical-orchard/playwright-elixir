defmodule Playwright.FrameElementTest do
  use Playwright.TestCase, async: true
  alias Playwright.{ElementHandle, Frame, Page}

  describe "Frame.frame_element/1" do
    test "returns the iframe element for a child frame", %{page: page, assets: assets} do
      Page.set_content(page, """
      <iframe id="my-iframe" src="#{assets.empty}"></iframe>
      """)

      Page.wait_for_load_state(page, "load")

      frames = Page.frames(page)
      child_frame = Enum.find(frames, fn f -> f.url =~ "empty.html" end)

      assert child_frame != nil

      element = Frame.frame_element(child_frame)
      assert %ElementHandle{} = element

      # Verify it's the iframe element
      tag_name = ElementHandle.evaluate(element, "e => e.tagName.toLowerCase()")
      assert tag_name == "iframe"

      # Verify it has our id
      id = ElementHandle.get_attribute(element, "id")
      assert id == "my-iframe"
    end

    test "returns error for main frame", %{page: page} do
      main_frame = Page.main_frame(page)

      result = Frame.frame_element(main_frame)

      assert {:error, _} = result
    end
  end
end
