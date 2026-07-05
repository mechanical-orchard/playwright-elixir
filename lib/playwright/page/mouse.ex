defmodule Playwright.Mouse do
  @moduledoc """
  Mouse provides methods for interacting with a virtual mouse.

  Every Page has its own Mouse, accessible via the page functions.

  ## Examples

      # Click at coordinates
      Mouse.click(page, 100, 200)

      # Right-click
      Mouse.click(page, 100, 200, button: "right")

      # Double-click
      Mouse.dblclick(page, 100, 200)

      # Drag and drop
      Mouse.move(page, 0, 0)
      Mouse.down(page)
      Mouse.move(page, 100, 100, steps: 10)
      Mouse.up(page)

      # Scroll
      Mouse.wheel(page, 0, 100)
  """

  use Playwright.SDK.ChannelOwner
  alias Playwright.Page

  @type button :: String.t()

  @doc """
  Clicks at the specified coordinates.

  ## Options

  - `:button` - `"left"`, `"right"`, or `"middle"` (default: `"left"`)
  - `:click_count` - Number of clicks (default: 1)
  - `:delay` - Time between mousedown and mouseup in ms (default: 0)
  """
  @spec click(Page.t(), number(), number(), keyword()) :: Page.t()
  def click(page, x, y, options \\ []) do
    params = %{x: x, y: y}
    params = if options[:button], do: Map.put(params, :button, options[:button]), else: params
    params = if options[:click_count], do: Map.put(params, :clickCount, options[:click_count]), else: params
    params = if options[:delay], do: Map.put(params, :delay, options[:delay]), else: params
    post!(page, :mouse_click, params)
  end

  @doc """
  Double-clicks at the specified coordinates.

  ## Options

  - `:button` - `"left"`, `"right"`, or `"middle"` (default: `"left"`)
  - `:delay` - Time between mousedown and mouseup in ms (default: 0)
  """
  @spec dblclick(Page.t(), number(), number(), keyword()) :: Page.t()
  def dblclick(page, x, y, options \\ []) do
    click(page, x, y, Keyword.put(options, :click_count, 2))
  end

  @doc """
  Dispatches a mousedown event.

  ## Options

  - `:button` - `"left"`, `"right"`, or `"middle"` (default: `"left"`)
  - `:click_count` - Number of clicks (default: 1)
  """
  @spec down(Page.t(), keyword()) :: Page.t()
  def down(page, options \\ []) do
    params = %{}
    params = if options[:button], do: Map.put(params, :button, options[:button]), else: params
    params = if options[:click_count], do: Map.put(params, :clickCount, options[:click_count]), else: params
    post!(page, :mouse_down, params)
  end

  @doc """
  Dispatches a mouseup event.

  ## Options

  - `:button` - `"left"`, `"right"`, or `"middle"` (default: `"left"`)
  - `:click_count` - Number of clicks (default: 1)
  """
  @spec up(Page.t(), keyword()) :: Page.t()
  def up(page, options \\ []) do
    params = %{}
    params = if options[:button], do: Map.put(params, :button, options[:button]), else: params
    params = if options[:click_count], do: Map.put(params, :clickCount, options[:click_count]), else: params
    post!(page, :mouse_up, params)
  end

  @doc """
  Moves the mouse to the specified coordinates.

  ## Options

  - `:steps` - Number of intermediate mousemove events (default: 1)
  """
  @spec move(Page.t(), number(), number(), keyword()) :: Page.t()
  def move(page, x, y, options \\ []) do
    params = %{x: x, y: y}
    params = if options[:steps], do: Map.put(params, :steps, options[:steps]), else: params
    post!(page, :mouse_move, params)
  end

  @doc """
  Dispatches a wheel event (scroll).

  ## Parameters

  - `delta_x` - Horizontal scroll amount in pixels
  - `delta_y` - Vertical scroll amount in pixels
  """
  @spec wheel(Page.t(), number(), number()) :: Page.t()
  def wheel(page, delta_x, delta_y) do
    post!(page, :mouse_wheel, %{deltaX: delta_x, deltaY: delta_y})
  end
end
