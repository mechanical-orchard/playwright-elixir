defmodule Playwright.Touchscreen do
  @moduledoc """
  Touchscreen provides methods for dispatching touch events.

  Touch events are dispatched on the page. To use touchscreen methods,
  you typically need to enable touch emulation via browser context options.

  ## Example

      # Create a context with touch enabled
      context = Browser.new_context(browser, %{has_touch: true})
      page = BrowserContext.new_page(context)

      # Tap at coordinates
      Touchscreen.tap(page, 100, 200)
  """

  alias Playwright.SDK.Channel

  @doc """
  Dispatches a `touchstart` and `touchend` event at the given coordinates.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `page` | `Page.t()` | The page to dispatch the tap event on |
  | `x` | `number()` | X coordinate relative to the viewport |
  | `y` | `number()` | Y coordinate relative to the viewport |

  ## Returns

  - `:ok`
  """
  @spec tap(Playwright.Page.t(), number(), number()) :: :ok
  def tap(%Playwright.Page{session: session, guid: guid}, x, y) do
    Channel.post(session, {:guid, guid}, :touchscreen_tap, %{x: x, y: y})
    :ok
  end
end
