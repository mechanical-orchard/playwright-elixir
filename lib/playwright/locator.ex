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
  alias Playwright.{ElementHandle, Frame, JSHandle, Locator, Page}
  alias Playwright.Runner.Channel

  @enforce_keys [:frame, :selector]
  defstruct [:frame, :selector]

  @type t() :: %__MODULE__{
          frame: Playwright.Frame.t(),
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
  | `frame`    | param  | `Frame.t() | Page.t()` |  |
  | `selector` | param  | `binary()`             | A Playwright selector. |
  """
  @spec new(Frame.t() | Page.t(), selector()) :: Locator.t()
  def new(frame, selector)

  def new(%Frame{} = frame, selector) do
    %__MODULE__{
      frame: frame,
      selector: selector
    }
  end

  def new(%Page{} = page, selector) do
    %__MODULE__{
      frame: Page.main_frame(page),
      selector: selector
    }
  end

  @spec all_inner_texts(Locator.t()) :: {:ok, [binary()]}
  def all_inner_texts(locator) do
    Frame.eval_on_selector_all(locator.frame, locator.selector, "ee => ee.map(e => e.innerText)")
  end

  @spec all_text_contents(Locator.t()) :: {:ok, [binary()]}
  def all_text_contents(locator) do
    Frame.eval_on_selector_all(locator.frame, locator.selector, "ee => ee.map(e => e.textContent || '')")
  end

  @spec bounding_box(Locator.t(), options()) :: {:ok, map() | nil}
  def bounding_box(%Locator{} = locator, options \\ %{}) do
    with_element(locator, options, fn handle ->
      ElementHandle.bounding_box(handle)
    end)
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
  | `:button`        | option | `:left`, `:right` or `:middle`    | `(default: :left)` |
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

  @spec count(Locator.t()) :: {:ok, term()}
  def count(%Locator{} = locator) do
    evaluate_all(locator, "ee => ee.length")
  end

  @doc """
  Double clicks the element.

  Performs the following steps:

    1. Wait for actionability checks on the matched element, unless
      `option: force` is set.
    2. Scroll the element into view if needed.
    3 Use `Page.Mouse` to double click in the center of the element, or the
      specified `option: position`.
    4. Wait for initiated navigations to either succeed or fail, unless
      `option: no_wait_after` is set. Note that if the first click of the
      `dblclick/3` triggers a navigation event, the call will throw.

  If the element is detached from the DOM at any moment during the action,
  the call throws.

  When all steps combined have not finished during the specified
  `option: timeout`, throws a `TimeoutError`. Passing `timeout: 0` disables
  this.

  > NOTE
  >
  > `dblclick/3` dispatches two `click` events and a single `dblclick` event.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name       | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `:button`        | option | `:left`, `:right` or `:middle`    | `(default: :left)` |
  | `:delay`         | option | `number() `                       | Time to wait between keydown and keyup in milliseconds. `(default: 0)` |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:modifiers`     | option | `[:alt, :control, :meta, :shift]` | Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used. |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}`                   | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`                       | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec dblclick(Locator.t(), options()) :: :ok
  def dblclick(locator, options \\ %{}) do
    Frame.dblclick(locator.frame, locator.selector, options)
  end

  @doc """
  Dispatches the `param: type` event on the element.

  Regardless of the visibility state of the element, the event is dispatched.

  Under the hood, creates an instance of an event based on the given type,
  initializes it with the `param: event_init` properties and dispatches it on
  the element.

  Events are composed, cancelable and bubble by default.

  The `param: event_init` is event-specific. Please refer to the events
  documentation for the lists of initial properties:

  - [DragEvent](https://developer.mozilla.org/en-US/docs/Web/API/DragEvent/DragEvent)
  - [FocusEvent](https://developer.mozilla.org/en-US/docs/Web/API/FocusEvent/FocusEvent)
  - [KeyboardEvent](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/KeyboardEvent)
  - [MouseEvent](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/MouseEvent)
  - [PointerEvent](https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/PointerEvent)
  - [TouchEvent](https://developer.mozilla.org/en-US/docs/Web/API/TouchEvent/TouchEvent)
  - [Event](https://developer.mozilla.org/en-US/docs/Web/API/Event/Event)

  ## Example

  Dispatch a 'click' event on the element. This is equivalent to calling
  `Playwright.ElementHandle.click/2`:

      Locator.dispatch_event(locator, :click)

  Specify a `Playwright.JSHandle` as the property value to be passed into the
  event:

      data_transfer = Page.evaluate_handle(page, "new DataTransfer()")
      Locator.dispatch_event(locator, :dragstart, { "dataTransfer": data_transfer })

  ## Returns

  - `:ok`

  ## Arguments

  | key / name       | type   |                         | description |
  | ---------------- | ------ | ----------------------- | ----------- |
  | `type`           | param  | `atom()` or `binary()`  | DOM event type: `:click`, `:dragstart`, etc. |
  | `event_init`     | param  | `evaluation_argument()` | Optional event-specific initialization properties. |
  | `:timeout`       | option | `number()`              | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec dispatch_event(Locator.t(), atom() | binary(), Frame.evaluation_argument(), options()) :: :ok
  def dispatch_event(locator, type, event_init \\ nil, options \\ %{})

  def dispatch_event(%Locator{} = locator, type, event_init, options) do
    options = Map.merge(options, %{strict: true})
    Frame.dispatch_event(locator.frame, locator.selector, type, event_init, options)
  end

  @doc """
  Resolves the given `Playwright.Locator` to the first matching DOM element.

  If no elements matching the query are visible, waits for them up to a given
  timeout. If multiple elements match the selector, throws.

  ## Returns

  - `{:ok, Playwright.ElementHandle.t()}`
  - `{:error, Playwright.Runner.Channel.Error.t()}`

  ## Arguments

  | key / name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec element_handle(Locator.t(), options()) :: {:ok, ElementHandle.t()} | {:error, Channel.Error.t()}
  def element_handle(%Locator{} = locator, options \\ %{}) do
    options = Map.merge(%{strict: true, state: "attached"}, options)

    with_element(locator, options, fn handle ->
      {:ok, handle}
    end)
  end

  @doc false
  def element_handle!(%Locator{} = locator, options \\ %{}) do
    case element_handle(locator, options) do
      # {:ok, nil} -> raise "No element found for selector: #{selector}"
      {:ok, handle} -> handle
    end
  end

  @doc """
  Resolves given locator to all matching DOM elements.

  ## Returns

  - `[Playwright.ElementHandle.t()]`
  """
  @spec element_handles(Locator.t()) :: {:ok, [ElementHandle.t()]}
  def element_handles(locator) do
    Frame.query_selector_all(locator.frame, locator.selector)
  end

  # NOTE: not really `| nil`... also Serializable or JSHandle
  @doc """
  ...
  """
  @spec evaluate(Locator.t(), binary(), ElementHandle.t() | nil, options()) :: {:ok, serializable()}
  def evaluate(locator, expression, arg \\ nil, options \\ %{})

  # NOTE: need to do all of the map-like things before a plain `map()`,
  # then do `map()`, then do anything else.
  def evaluate(%Locator{} = locator, expression, arg, options)
      when is_struct(arg, ElementHandle) do
    with_element(locator, options, fn handle ->
      ElementHandle.evaluate(handle, expression, arg)
    end)
  end

  def evaluate(%Locator{} = locator, expression, options, _)
      when is_map(options) do
    with_element(locator, options, fn handle ->
      ElementHandle.evaluate(handle, expression)
    end)
  end

  def evaluate(%Locator{} = locator, expression, arg, options) do
    with_element(locator, options, fn handle ->
      ElementHandle.evaluate(handle, expression, arg)
    end)
  end

  @doc false
  def evaluate!(%Locator{} = locator, expression, arg \\ nil, options \\ %{}) do
    {:ok, result} = evaluate(locator, expression, arg, options)
    result
  end

  @doc """
  ...
  """
  @spec evaluate_all(Locator.t(), binary(), ElementHandle.t() | nil) :: {:ok, [serializable()]}
  def evaluate_all(locator, expression, arg \\ nil)

  def evaluate_all(%Locator{} = locator, expression, arg) do
    Frame.eval_on_selector_all(locator.frame, locator.selector, expression, arg)
  end

  @doc """
  Returns the result of `param: expression` as a `Playwright.JSHandle`.

  Passes the handle as the first argument to `param: expression`.

  The only difference between `Playwright.Locator.evaluate/4` and
  `Playwright.Locator.evaluate_handle/3` is that `evaluate_handle` returns
  `JSHandle`.

  See `Playwright.Page.evaluate_handle` for more details.

  ## Returns

    - `{:ok, Playwright.JSHandle.t()}`
    - `{:error, Playwright.Runner.Channel.Error.t()}`

  ## Arguments

  | key / name   | type   |            | description |
  | ------------ | ------ | ---------- | ----------- |
  | `expression` | param  | `binary()` | JavaScript expression to be evaluated in the browser context. If it looks like a function declaration, it is interpreted as a function. Otherwise, evaluated as an expression. |
  | `arg`        | param  | `any()`    | Argument to pass to `expression` `(optional)` |
  | `:timeout`   | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec evaluate_handle(Locator.t(), binary(), any(), options()) :: {:ok, JSHandle.t()} | {:error, Channel.Error.t()}
  def evaluate_handle(locator, expression, arg \\ nil, options \\ %{})

  # NOTE: need to do all of the map-like things before a plain `map()`,
  # then do `map()`, then do anything else.
  def evaluate_handle(%Locator{} = locator, expression, arg, options)
      when is_struct(arg, ElementHandle) do
    options = Map.merge(%{strict: true, state: "attached"}, options)

    with_element(locator, options, fn handle ->
      ElementHandle.evaluate_handle(handle, expression, arg)
    end)
  end

  def evaluate_handle(%Locator{} = locator, expression, options, _)
      when is_map(options) do
    options = Map.merge(%{strict: true, state: "attached"}, options)

    with_element(locator, options, fn handle ->
      ElementHandle.evaluate_handle(handle, expression)
    end)
  end

  def evaluate_handle(%Locator{} = locator, expression, arg, options) do
    options = Map.merge(%{strict: true, state: "attached"}, options)

    with_element(locator, options, fn handle ->
      ElementHandle.evaluate_handle(handle, expression, arg)
    end)
  end

  @doc """
  Fills a form field or `contenteditable` element with text.

  Waits for an element matching `param: selector`, waits for "actionability
  checks", focuses the element, fills it and triggers an input event after
  filling.

  If the target element is not an `<input>`, `<textarea>` or `contenteditable`
  element, this function raises an error. However, if the element is inside the
  `<label>` element that has an associated control, the control will be filled
  instead.

  > NOTE
  >
  > - Pass an empty string to clear the input field.
  > - To send fine-grained keyboard events, use `Playwright.Locator.type/3`.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name       | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `value`          | param  | `binary()`                        | Value to fill for the `<input>`, `<textarea>` or `[contenteditable]` element |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec fill(Locator.t(), binary(), options()) :: :ok
  def fill(%Locator{} = locator, value, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.fill(locator.frame, locator.selector, value, options)
  end

  @spec first(Locator.t()) :: Locator.t()
  def first(%Locator{} = context) do
    locator(context, "nth=0")
  end

  @doc """
  Calls [focus](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/focus) on the element.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec focus(Locator.t(), options()) :: :ok
  def focus(%Locator{} = locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.focus(locator.frame, locator.selector, options)
  end

  @spec get_attribute(Locator.t(), binary(), options()) :: {:ok, binary() | nil}
  def get_attribute(%Locator{} = locator, name, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.get_attribute(locator.frame, locator.selector, name, options)
  end

  @doc """
  Hovers over the element.

  Performs the following steps:

  1. Wait for actionability checks on the matched element, unless
    `option: force` option is set. If the element is detached during the checks,
    the whole action is retried.
  2. Scroll the element into view if needed.
  3. Use `Page.Mouse` to hover over the center of the element, or the specified
    `option: position`.
  4. Wait for initiated navigations to either succeed or fail, unless
    `option: no_wait_after` is set.

  When all steps combined have not finished during the specified `option: timeout`,
  throws a `TimeoutError`. Passing `0` timeout disables this.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name       | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `selector`       | param  | `binary()`                        | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:modifiers`     | option | `[:alt, :control, :meta, :shift]` | Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used. |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}`                   | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`                       | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec hover(Locator.t(), options()) :: :ok
  def hover(%Locator{} = locator, options \\ %{}) do
    Frame.hover(locator.frame, locator.selector, options)
  end

  @spec inner_html(Locator.t(), options()) :: {:ok, binary()}
  def inner_html(locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.inner_html(locator.frame, locator.selector, options)
  end

  @spec inner_text(Locator.t(), options()) :: {:ok, binary()}
  def inner_text(locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.inner_text(locator.frame, locator.selector, options)
  end

  @spec input_value(Locator.t(), options()) :: {:ok, binary()}
  def input_value(locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.input_value(locator.frame, locator.selector, options)
  end

  def_locator(:is_checked, :is_checked)
  def_locator(:is_disabled, :is_disabled)
  def_locator(:is_editable, :is_editable)
  def_locator(:is_enabled, :is_enabled)
  def_locator(:is_hidden, :is_hidden)
  def_locator(:is_visible, :is_visible)

  @spec last(Locator.t()) :: Locator.t()
  def last(%Locator{} = context) do
    locator(context, "nth=-1")
  end

  @spec locator(Locator.t(), binary()) :: Locator.t()
  def locator(locator, selector) do
    Locator.new(locator.frame, "#{locator.selector} >> #{selector}")
  end

  @spec nth(Locator.t(), term()) :: Locator.t()
  def nth(context, index) do
    locator(context, "nth=#{index}")
  end

  @spec press(Locator.t(), binary(), options()) :: :ok
  def press(locator, key, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.press(locator.frame, locator.selector, key, options)
  end

  @spec screenshot(Locator.t(), options()) :: {:ok, binary()}
  def screenshot(locator, options \\ %{}) do
    with_element(locator, options, fn handle ->
      ElementHandle.screenshot(handle, options)
    end)
  end

  @spec scroll_into_view(Locator.t(), options()) :: :ok
  def scroll_into_view(%Locator{} = locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})

    with_element(locator, options, fn handle ->
      ElementHandle.scroll_into_view(handle, options)
    end)
  end

  @doc """
  Selects one or more options from a `<select>` element.

  Performs the following steps:

  1. Waits for actionability checks
  2. Waits until all specified options are present in the `<select>` element
  3. Selects those options

  If the target element is not a `<select>` element, raises an error. However,
  if the element is inside the `<label>` element that has an associated control,
  the control will be used instead.

  Returns the list of option values that have been successfully selected.

  Triggers a change and input event once all the provided options have been selected.

  ## Example
      locator = Page.locator(page, "select#colors")

      # single selection matching the value
      Locator.select_option(locator, "blue")

      # single selection matching both the label
      Locator.select_option(locator, %{label: "blue"})

      # multiple selection
      Locator.select_option(locator, %{value: ["red", "green", "blue"]})

  ## Returns

    - `{:ok, [binary()]}`

  ## Arguments

  | key / name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `values`         | param  | `any()`         | Options to select. |
  | `:force`         | option | `boolean()`     | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |

  ### On `values`

  If the `<select>` has the `multiple` attribute, all matching options are
  selected, otherwise only the first option matching one of the passed options
  is selected.

  String values are equivalent to `%{value: "string"}`.

  Option is considered matching if all specified properties match.

  - `value <binary>` Matches by `option.value`. `(optional)`.
  - `label <binary>` Matches by `option.label`. `(optional)`.
  - `index <number>` Matches by the index. `(optional)`.
  """
  @spec select_option(Locator.t(), any(), options()) :: {:ok, [binary()]}
  def select_option(locator, values, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.select_option(locator.frame, locator.selector, values, options)
  end

  @spec select_text(Locator.t(), options()) :: :ok
  def select_text(locator, options \\ %{}) do
    with_element(locator, options, fn handle ->
      ElementHandle.select_text(handle, options)
    end)
  end

  # ---

  # @spec set_checked(Locator.t(), boolean(), options()) :: :ok
  # def set_checked(locator, checked, options \\ %{})

  # ---

  @spec set_input_files(Locator.t(), any(), options()) :: :ok
  def set_input_files(locator, files, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.set_input_files(locator.frame, locator.selector, files, options)
  end

  def string(locator) do
    "Locator@#{locator.selector}"
  end

  # ---

  # @spec tap(Locator.t(), options()) :: :ok
  # def tap(locator, options \\ %{})

  # ---

  def_locator(:text_content, :text_content)

  @spec type(Locator.t(), binary(), options()) :: :ok
  def type(%Locator{} = locator, text, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.type(locator.frame, locator.selector, text, options)
  end

  @doc """
  Unchecks the (checkmark) element by performing the following steps:

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
  def_locator(:uncheck, :uncheck)

  @doc """
  Returns when element specified by locator satisfies `option: state`.

  If target element already satisfies the condition, the method returns
  immediately. Otherwise, waits for up to `option: timeout` milliseconds until
  the condition is met.
  """
  def_locator(:wait_for, :wait_for_selector)

  # private
  # ---------------------------------------------------------------------------

  defp with_element(locator, options, task) do
    case Channel.await(locator.frame, {:selector, locator.selector}, options) do
      {:ok, handle} ->
        task.(handle)

      {:error, _} = error ->
        error
    end
  end
end
