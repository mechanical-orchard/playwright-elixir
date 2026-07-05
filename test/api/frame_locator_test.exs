defmodule Playwright.FrameLocatorTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Frame, Locator, Page}
  alias Playwright.Page.FrameLocator

  describe "Page.frame_locator/2" do
    test "returns a FrameLocator struct", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)

      result = Page.frame_locator(page, "#frame1")

      assert %FrameLocator{} = result
      assert result.selector == "#frame1"
    end
  end

  describe "Frame.frame_locator/2" do
    test "returns a FrameLocator struct", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)
      frame = Page.main_frame(page)

      result = Frame.frame_locator(frame, "#frame1")

      assert %FrameLocator{} = result
      assert result.selector == "#frame1"
    end
  end

  describe "FrameLocator.locator/2" do
    test "locates elements inside an iframe", %{assets: assets, page: page} do
      _frame = attach_frame(page, "frame1", assets.prefix <> "/input/button.html")

      button =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.locator("button")

      assert %Locator{} = button
      assert Locator.text_content(button) == "Click target"
    end

    test "can click elements inside an iframe", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<div style="height:100px">spacer</div>|)
      frame = attach_frame(page, "frame1", assets.prefix <> "/input/button.html")

      page
      |> Page.frame_locator("#frame1")
      |> FrameLocator.locator("button")
      |> Locator.click()

      assert Frame.evaluate(frame, "window.result") == "Clicked"
    end
  end

  describe "FrameLocator.first/1, last/1, nth/2" do
    test "first returns FrameLocator with nth=0 selector", %{page: page} do
      Page.set_content(page, ~s|
        <iframe class="frame"></iframe>
        <iframe class="frame"></iframe>
      |)

      fl = Page.frame_locator(page, "iframe.frame")
      first_fl = FrameLocator.first(fl)

      assert %FrameLocator{} = first_fl
      assert first_fl.selector == "iframe.frame >> nth=0"
    end

    test "last returns FrameLocator with nth=-1 selector", %{page: page} do
      Page.set_content(page, ~s|
        <iframe class="frame"></iframe>
        <iframe class="frame"></iframe>
      |)

      fl = Page.frame_locator(page, "iframe.frame")
      last_fl = FrameLocator.last(fl)

      assert %FrameLocator{} = last_fl
      assert last_fl.selector == "iframe.frame >> nth=-1"
    end

    test "nth returns FrameLocator with specified index", %{page: page} do
      Page.set_content(page, ~s|<iframe class="frame"></iframe>|)

      fl = Page.frame_locator(page, "iframe.frame")
      nth_fl = FrameLocator.nth(fl, 2)

      assert %FrameLocator{} = nth_fl
      assert nth_fl.selector == "iframe.frame >> nth=2"
    end
  end

  describe "FrameLocator.frame_locator/2 (nested)" do
    test "creates nested frame selector", %{page: page} do
      Page.set_content(page, ~s|<iframe id="outer"></iframe>|)

      nested_fl =
        page
        |> Page.frame_locator("#outer")
        |> FrameLocator.frame_locator("#inner")

      assert %FrameLocator{} = nested_fl
      assert nested_fl.selector == "#outer >> internal:control=enter-frame >> #inner"
    end
  end

  describe "FrameLocator.owner/1" do
    test "returns Locator pointing to the iframe element", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1" title="My Frame"></iframe>|)

      owner_locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.owner()

      assert %Locator{} = owner_locator
      assert Locator.get_attribute(owner_locator, "title") == "My Frame"
    end
  end

  describe "FrameLocator.get_by_text/3" do
    test "locates element by text inside iframe", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)

      Page.evaluate(page, """
        const iframe = document.querySelector('#frame1');
        iframe.contentDocument.body.innerHTML = '<div>Hello World</div>';
      """)

      locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.get_by_text("Hello World")

      assert %Locator{} = locator
      assert String.contains?(locator.selector, "internal:control=enter-frame")
      assert String.contains?(locator.selector, "internal:text=")
    end
  end

  describe "FrameLocator.get_by_role/3" do
    test "locates element by role inside iframe", %{assets: assets, page: page} do
      Page.set_content(page, ~s|<div style="height:100px">spacer</div>|)
      frame = attach_frame(page, "frame1", assets.prefix <> "/input/button.html")

      locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.get_by_role("button")

      assert %Locator{} = locator
      Locator.click(locator)

      assert Frame.evaluate(frame, "window.result") == "Clicked"
    end
  end

  describe "FrameLocator.get_by_test_id/2" do
    test "locates element by test id inside iframe", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)

      Page.evaluate(page, """
        const iframe = document.querySelector('#frame1');
        iframe.contentDocument.body.innerHTML = '<button data-testid="submit-btn">Submit</button>';
      """)

      locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.get_by_test_id("submit-btn")

      assert %Locator{} = locator
      assert String.contains?(locator.selector, "internal:control=enter-frame")
      assert String.contains?(locator.selector, "internal:testid=")
    end
  end

  describe "FrameLocator.get_by_label/3" do
    test "locates input by label inside iframe", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)

      Page.evaluate(page, """
        const iframe = document.querySelector('#frame1');
        iframe.contentDocument.body.innerHTML = '<label for="user">Username</label><input id="user" />';
      """)

      locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.get_by_label("Username")

      assert %Locator{} = locator
      assert String.contains?(locator.selector, "internal:control=enter-frame")
      assert String.contains?(locator.selector, "internal:label=")
    end
  end

  describe "FrameLocator.get_by_placeholder/3" do
    test "returns Locator with correct selector", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)

      locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.get_by_placeholder("Enter email")

      assert %Locator{} = locator
      assert String.contains?(locator.selector, "internal:control=enter-frame")
      assert String.contains?(locator.selector, "internal:attr=[placeholder=")
    end
  end

  describe "FrameLocator.get_by_alt_text/3" do
    test "returns Locator with correct selector", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)

      locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.get_by_alt_text("Logo image")

      assert %Locator{} = locator
      assert String.contains?(locator.selector, "internal:control=enter-frame")
      assert String.contains?(locator.selector, "internal:attr=[alt=")
    end
  end

  describe "FrameLocator.get_by_title/3" do
    test "returns Locator with correct selector", %{page: page} do
      Page.set_content(page, ~s|<iframe id="frame1"></iframe>|)

      locator =
        page
        |> Page.frame_locator("#frame1")
        |> FrameLocator.get_by_title("Help tooltip")

      assert %Locator{} = locator
      assert String.contains?(locator.selector, "internal:control=enter-frame")
      assert String.contains?(locator.selector, "internal:attr=[title=")
    end
  end
end
