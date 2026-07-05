defmodule Playwright.TouchscreenTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Page, Touchscreen}

  describe "Touchscreen.tap/3" do
    @tag :headed
    test "dispatches touch events at coordinates", %{browser: browser, assets: _assets} do
      # Create a context with touch enabled
      context = Playwright.Browser.new_context(browser, %{has_touch: true})
      {:ok, page} = Playwright.BrowserContext.new_page(context)

      Page.set_content(page, """
      <div id="target" style="width: 100px; height: 100px; background: blue;"></div>
      <script>
        window.touchEvents = [];
        document.getElementById('target').addEventListener('touchstart', e => {
          window.touchEvents.push({type: 'touchstart', x: e.touches[0].clientX, y: e.touches[0].clientY});
        });
        document.getElementById('target').addEventListener('touchend', e => {
          window.touchEvents.push({type: 'touchend'});
        });
      </script>
      """)

      # Tap at center of target
      Touchscreen.tap(page, 50, 50)

      # Check that touch events were received
      events = Page.evaluate(page, "() => window.touchEvents")

      assert length(events) == 2
      assert Enum.at(events, 0)["type"] == "touchstart"
      assert Enum.at(events, 1)["type"] == "touchend"

      Playwright.BrowserContext.close(context)
    end

    test "returns :ok", %{browser: browser} do
      # Create a context with touch enabled
      context = Playwright.Browser.new_context(browser, %{has_touch: true})
      page = Playwright.BrowserContext.new_page(context)

      Page.set_content(page, "<div>Hello</div>")

      result = Touchscreen.tap(page, 10, 10)
      assert result == :ok

      Playwright.BrowserContext.close(context)
    end
  end
end
