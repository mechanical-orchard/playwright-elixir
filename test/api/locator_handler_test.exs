defmodule Playwright.LocatorHandlerTest do
  use Playwright.TestCase, async: false
  alias Playwright.{Locator, Page}

  describe "add_locator_handler/4" do
    test "auto-dismisses overlay when it appears", %{page: page} do
      Page.set_content(page, """
        <button id="show">Show Dialog</button>
        <div id="dialog" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5);">
          <button id="close">Close</button>
        </div>
        <button id="target">Target</button>
        <script>
          document.getElementById('show').onclick = () => {
            document.getElementById('dialog').style.display = 'block';
          };
          document.getElementById('close').onclick = () => {
            document.getElementById('dialog').style.display = 'none';
          };
        </script>
      """)

      dialog = Page.locator(page, "#dialog")
      close_btn = Page.locator(page, "#close")

      # Register handler to auto-close dialog
      :ok =
        Page.add_locator_handler(page, dialog, fn _loc ->
          Locator.click(close_btn)
        end)

      # Click show button which displays the dialog
      Page.click(page, "#show")

      # Now click target - should work because handler will dismiss dialog
      Page.click(page, "#target")

      # Dialog should be hidden
      assert Locator.is_hidden(dialog)
    end

    test "handler receives the locator as argument", %{page: page} do
      Page.set_content(page, """
        <div id="banner" style="display:block;">Cookie Banner</div>
        <button id="action">Action</button>
        <script>
          window.receivedText = null;
        </script>
      """)

      banner = Page.locator(page, "#banner")

      :ok =
        Page.add_locator_handler(page, banner, fn loc ->
          # Get text from the locator passed to handler
          text = Locator.text_content(loc)
          Page.evaluate(page, "text => window.receivedText = text", text)
          Page.evaluate(page, "document.getElementById('banner').style.display = 'none'")
        end)

      Page.click(page, "#action")

      # Verify handler received the locator and could use it
      assert Page.evaluate(page, "window.receivedText") == "Cookie Banner"
    end

    test "times option limits executions", %{page: page} do
      Page.set_content(page, """
        <div id="counter">0</div>
        <div id="overlay" style="display:block;">Overlay</div>
        <button id="action">Action</button>
        <script>
          let count = 0;
          window.incrementCounter = () => {
            count++;
            document.getElementById('counter').textContent = count;
          };
        </script>
      """)

      overlay = Page.locator(page, "#overlay")

      # Handler should only run twice
      :ok =
        Page.add_locator_handler(
          page,
          overlay,
          fn _loc ->
            Page.evaluate(page, "window.incrementCounter()")
            Page.evaluate(page, "document.getElementById('overlay').style.display = 'none'")
          end,
          %{times: 2}
        )

      # First action triggers handler
      Page.click(page, "#action")
      assert Page.text_content(page, "#counter") == "1"

      # Show overlay again
      Page.evaluate(page, "document.getElementById('overlay').style.display = 'block'")

      # Second action triggers handler (times: 2)
      Page.click(page, "#action")
      assert Page.text_content(page, "#counter") == "2"

      # Show overlay again
      Page.evaluate(page, "document.getElementById('overlay').style.display = 'block'")

      # Third action - handler should be exhausted
      # Hide overlay manually so click can proceed
      Page.evaluate(page, "document.getElementById('overlay').style.display = 'none'")
      Page.click(page, "#action")

      # Counter should still be 2 (handler didn't run third time)
      assert Page.text_content(page, "#counter") == "2"
    end
  end

  describe "remove_locator_handler/2" do
    test "stops handling after removal", %{page: page} do
      Page.set_content(page, """
        <div id="counter">0</div>
        <div id="overlay" style="display:block;">Overlay</div>
        <button id="action">Action</button>
        <script>
          let count = 0;
          window.incrementCounter = () => {
            count++;
            document.getElementById('counter').textContent = count;
          };
        </script>
      """)

      overlay = Page.locator(page, "#overlay")

      # Add handler
      :ok =
        Page.add_locator_handler(page, overlay, fn _loc ->
          Page.evaluate(page, "window.incrementCounter()")
          Page.evaluate(page, "document.getElementById('overlay').style.display = 'none'")
        end)

      # First action triggers handler
      Page.click(page, "#action")
      assert Page.text_content(page, "#counter") == "1"

      # Remove handler
      :ok = Page.remove_locator_handler(page, overlay)

      # Show overlay again and manually hide it
      Page.evaluate(page, "document.getElementById('overlay').style.display = 'block'")
      Page.evaluate(page, "document.getElementById('overlay').style.display = 'none'")

      # Action should work but handler shouldn't have been called
      Page.click(page, "#action")

      # Counter should still be 1 (handler was removed)
      assert Page.text_content(page, "#counter") == "1"
    end
  end
end
