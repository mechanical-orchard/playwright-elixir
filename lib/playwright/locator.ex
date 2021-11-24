defmodule Playwright.Locator do
  @moduledoc """
  `Playwright.Locator` represents a view to the element(s) on the page.
  It captures the logic sufficient to retrieve the element at any given moment.
  `Locator` can be created with the `Playwright.Locator.new/2` function.

  ## Example

      locator = Page.Locator.new(page, "a#exists")
      Locator.click(locator)

  The difference between the `Locator` and `Playwright.ElementHandle`
  is that the latter points to a particular element, while `Locator` captures
  the logic of how to retrieve that element.

  ## ElementHandle Example

  In the example below, `handle` points to a particular DOM element on page. If
  that element changes text or is used by React to render an entirely different
  component, `handle` is still pointing to that very DOM element. This can lead
  to unexpected behaviors.

      {:ok, handle} = Page.query_selector(page, "text=Submit")
      ElementHandle.hover(handle)
      ElementHandle.click(handle)

  ## Locator Example

  With the locator, every time the element is used, up-to-date DOM element is
  located in the page using the selector. So in the snippet below, underlying
  DOM element is going to be located twice.

      locator = Page.Locator.new(page, "a#exists")
      :ok = Page.Locator.hover(locator)
      :ok = Page.Locator.click(locator)

  ## Strictness

  Locators are strict. This means that all operations on locators that imply
  some target DOM element will throw if more than one element matches given
  selector.

      alias Page.Locator
      locator = Locator.new(page, "button")

      # Throws if there are several buttons in DOM:
      Locator.click(locator)

      # Works because we explicitly tell locator to pick the first element:
      Locator.first(locator) |> Locator.click()

      # Works because count knows what to do with multiple matches:
      Locator.count(locator)
  """

  import Playwright.Locator.Macros
  alias Playwright.{ElementHandle, Frame, Locator, Page}
  alias Playwright.Runner.Channel

  @enforce_keys [:owner, :selector]
  defstruct [:owner, :selector]

  @type t() :: %__MODULE__{
          owner: Playwright.Frame.t(),
          selector: selector()
        }

  @type options() :: %{optional(:timeout) => non_neg_integer()}

  @type options_position() :: %{
          optional(:x) => number(),
          optional(:y) => number()
        }

  @type options_click() :: %{
          optional(:button) => param_input_button(),
          optional(:click_count) => number(),
          optional(:delay) => number(),
          optional(:force) => boolean(),
          optional(:modifiers) => [:alt | :control | :meta | :shift],
          optional(:no_wait_after) => boolean(),
          optional(:position) => options_position(),
          optional(:timeout) => number(),
          optional(:trial) => boolean()
        }

  @type param_input_button() :: :left | :right | :middle

  @type selector() :: String.t()

  @type serializable :: any()

  @doc """
  Returns a `%Playwright.Locator{}`.

  ## Arguments

  | key / name | type   |                        | description |
  | ---------- | ------ | ---------------------- | ----------- |
  | `owner`    | param  | `Frame.t() | Page.t()` |  |
  | `selector` | param  | `binary()`             | A Playwright selector. |
  """
  @spec new(Frame.t() | Page.t(), selector()) :: Locator.t()
  def new(owner, selector)

  def new(%Frame{} = frame, selector) do
    %__MODULE__{
      owner: frame,
      selector: selector
    }
  end

  def new(%Page{} = page, selector) do
    %__MODULE__{
      owner: Page.main_frame(page),
      selector: selector
    }
  end

  @doc """
  Checks the (checkmark) element by performing the following steps:

    1. Ensure that element is a checkbox or a radio input. If not, this method
      throws. If the element is already checked, this method returns immediately.
    2. Wait for actionability checks on the element, unless force option is set.
    3. Scroll the element into view if needed.
    4. Use `Playwright.Page.Mouse` to click in the center of the element.
    5. Wait for initiated navigations to either succeed or fail, unless
      `option: no_wait_after` is set.
    6. Ensure that the element is now checked. If not, this method throws.

  If the element is detached from the DOM at any moment during the action,
  this method throws.

  When all steps combined have not finished during the specified timeout, this
  method throws a `TimeoutError`. Passing `0` timeout disables this.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `:force`         | option | `boolean()`     | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}` | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`     | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  def_locator(:check, :check)

  @doc """
  Clicks the element by performing the following steps:

  1. Wait for actionability checks on the element, unless `option: force` is set.
  2. Scroll the element into view if needed.
  3. Use `Playwright.Page.Mouse` to click in the center of the element, or
     the specified position.
  4. Wait for initiated navigations to either succeed or fail, unless
     `option: no_wait_after` is set.

  If the element is detached from the DOM at any moment during the action, this method throws.

  When all steps combined have not finished during the specified timeout, this method throws a
  `Playwright.Runner.Channel.Error.t()`. Passing `0` timeout disables this.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name       | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `:button`        | option | `:left`, `:right` or `:middle`  | `(default: :left)` |
  | `:click_count`   | option | `number()`                        | See [MDN: `UIEvent.detail`](https://developer.mozilla.org/en-US/docs/Web/API/UIEvent/detail) `(default: 1)` |
  | `:delay`         | option | `number()`                        | Time to wait between `mousedown` and `mouseup` in milliseconds. `(default: 0)` |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:modifiers`     | option | `[:alt, :control, :meta, :shift]` | Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used. |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}`                   | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`                       | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  def_locator(:click, :click, options_click())

  @doc """
  Returns when element specified by locator satisfies the `:state` option.

  If target element already satisfies the condition, the method returns
  immediately. Otherwise, waits for up to `option: timeout` milliseconds until
  the condition is met.
  """
  def_locator(:wait_for, :wait_for_selector)

  # NOTE: not really `| nil`... also Serializable or JSHandle
  @spec evaluate(Locator.t(), binary(), ElementHandle.t() | nil, options()) :: {:ok, any()}
  def evaluate(locator, expression, arg \\ nil, options \\ %{})

  def evaluate(%Locator{} = locator, expression, arg, options)
      when is_struct(arg, Playwright.ElementHandle) do
    with_element(
      locator,
      fn handle ->
        ElementHandle.evaluate(handle, expression, arg)
      end,
      options
    )
  end

  def evaluate(%Locator{} = locator, expression, options, _)
      when is_map(options) do
    with_element(
      locator,
      fn handle ->
        ElementHandle.evaluate(handle, expression)
      end,
      options
    )
  end

  def evaluate(%Locator{} = locator, expression, arg, options) do
    with_element(
      locator,
      fn handle ->
        ElementHandle.evaluate(handle, expression, arg)
      end,
      options
    )
  end

  @spec evaluate_all(Locator.t(), binary(), ElementHandle.t() | nil) :: {:ok, [any()]}
  def evaluate_all(locator, expression, arg \\ nil)

  def evaluate_all(%Locator{} = locator, expression, arg) do
    Frame.eval_on_selector_all(locator.owner, locator.selector, expression, arg)
  end

  def_locator(:is_checked, :is_checked)

  # fill
  # first
  # get_attribute
  # inner_html
  # inner_text
  # last
  # text_content

  # private
  # ---------------------------------------------------------------------------

  defp with_element(locator, task, options) do
    case Channel.await(locator.owner, {:selector, locator.selector}, options) do
      {:ok, handle} ->
        task.(handle)

      {:error, _} = error ->
        error
    end
  end
end
