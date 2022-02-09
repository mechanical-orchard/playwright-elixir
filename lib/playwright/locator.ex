defmodule Playwright.Locator do
  @moduledoc """
  `Playwright.Locator` represents a view to the element(s) on the page.
  It captures the logic sufficient to retrieve the element at any given moment.
  `Locator` can be created with the `Playwright.Locator.new/2` function.

  See also `Playwright.Page.locator/2`.

  ## Example

      locator = Playwright.Locator.new(page, "a#exists")
      Playwright.Locator.click(locator)

  The difference between the `Playwright.Locator` and `Playwright.ElementHandle`
  is that the latter points to a particular element, while `Playwright.Locator` captures
  the logic of how to retrieve that element.

  ## ElementHandle Example

  In the example below, `handle` points to a particular DOM element on page. If
  that element changes text or is used by React to render an entirely different
  component, `handle` is still pointing to that very DOM element. This can lead
  to unexpected behaviors.

      handle = Page.query_selector(page, "text=Submit")
      ElementHandle.hover(handle)
      ElementHandle.click(handle)

  ## Locator Example

  With the locator, every time the element is used, up-to-date DOM element is
  located in the page using the selector. So in the snippet below, underlying
  DOM element is going to be located twice.

      locator = Playwright.Locator.new(page, "a#exists")
      :ok = Playwright.Locator.hover(locator)
      :ok = Playwright.Locator.click(locator)

  ## Strictness

  Locators are strict. This means that all operations on locators that imply
  some target DOM element will throw if more than one element matches given
  selector.

      alias Playwright.Locator
      locator = Locator.new(page, "button")

      # Throws if there are several buttons in DOM:
      Locator.click(locator)

      # Works because we explicitly tell locator to pick the first element:
      Locator.first(locator) |> Locator.click()

      # Works because count knows what to do with multiple matches:
      Locator.count(locator)
  """

  alias Playwright.{Channel, ElementHandle, Frame, Locator, Page}

  @enforce_keys [:frame, :selector]
  defstruct [:frame, :selector]

  @type t() :: %__MODULE__{
          frame: Playwright.Frame.t(),
          selector: selector()
        }

  @type options() :: %{optional(:timeout) => non_neg_integer()}

  @type options_keyboard() :: %{
          optional(:delay) => non_neg_integer(),
          optional(:no_wait_after) => boolean(),
          optional(:timeout) => non_neg_integer()
        }

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

  @type selector() :: binary()

  @type serializable :: any()

  @doc """
  Returns a `%Playwright.Locator{}`.

  ## Arguments

  | key/name | type   |                        | description |
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

  @doc """
  Returns an list of `node.innerText` values for all matching nodes.

  ## Returns

    - `[binary()]`
  """
  @spec all_inner_texts(t()) :: [binary()]
  def all_inner_texts(%Locator{} = locator) do
    Frame.eval_on_selector_all(locator.frame, locator.selector, "ee => ee.map(e => e.innerText)")
  end

  @doc """
  Returns an list of `node.textContent` values for all matching nodes.

  ## Returns

    - `[binary()]`
  """
  @spec all_text_contents(t()) :: [binary()]
  def all_text_contents(%Locator{} = locator) do
    Frame.eval_on_selector_all(locator.frame, locator.selector, "ee => ee.map(e => e.textContent || '')")
  end

  @doc """
  Returns the bounding box of the element, or `nil` if the element is not visible.

  The bounding box is calculated relative to the main frame viewport which is
  usually the same as the browser window.

  Scrolling affects the returned bounding box, similarly to
  [Element.getBoundingClientRect](https://developer.mozilla.org/en-US/docs/Web/API/Element/getBoundingClientRect).

  That means `x` and/or `y` may be negative.

  Elements from child frames return the bounding box relative to the main frame,
  unlike [Element.getBoundingClientRect](https://developer.mozilla.org/en-US/docs/Web/API/Element/getBoundingClientRect).

  Assuming the page is static, it is safe to use bounding box coordinates to perform input. For example, the following snippet should click the center of the element:options()

      box = Locator.bounding_box(locator)
      Page.Mouse.click(page, box.x + box.width / 2, box.y + box.height / 2)

  ## Returns

    - `%{x: x, y: y, width: width, height: height}`
    - `nil`

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  """
  @spec bounding_box(t(), options()) :: map() | nil
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

  | key/name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `:force`         | option | `boolean()`     | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}` | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`     | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec check(t(), options()) :: :ok
  def check(%Locator{} = locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.check(locator.frame, locator.selector, options)
  end

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
  `Playwright.Channel.Error.t()`. Passing `0` timeout disables this.

  ## Returns

    - `:ok`

  ## Arguments

  | key/name       | type   |                                   | description |
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
  @spec click(t(), options_click()) :: :ok
  def click(%Locator{} = locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.click(locator.frame, locator.selector, options)
  end

  @doc """
  Returns the number of elements matching given selector.

  ## Returns

    - `number()`
  """
  @spec count(t()) :: number()
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

  | key/name       | type   |                                   | description |
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
  @spec dblclick(t(), options()) :: :ok
  def dblclick(%Locator{} = locator, options \\ %{}) do
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

  | key/name       | type   |                         | description |
  | ---------------- | ------ | ----------------------- | ----------- |
  | `type`           | param  | `atom()` or `binary()`  | DOM event type: `:click`, `:dragstart`, etc. |
  | `event_init`     | param  | `evaluation_argument()` | Optional event-specific initialization properties. |
  | `:timeout`       | option | `number()`              | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec dispatch_event(t(), atom() | binary(), Frame.evaluation_argument(), options()) :: :ok
  def dispatch_event(%Locator{} = locator, type, event_init \\ nil, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.dispatch_event(locator.frame, locator.selector, type, event_init, options)
  end

  @doc """
  Resolves the given `Playwright.Locator` to the first matching DOM element.

  If no elements matching the query are visible, waits for them up to a given
  timeout. If multiple elements match the selector, throws.

  ## Returns

  - `Playwright.ElementHandle.t()`
  - `{:error, Playwright.Channel.Error.t()}`

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec element_handle(t(), options()) :: ElementHandle.t() | {:error, Channel.Error.t()}
  def element_handle(%Locator{} = locator, options \\ %{}) do
    options = Map.merge(%{strict: true, state: "attached"}, options)

    with_element(locator, options, fn handle ->
      handle
    end)
  end

  @doc """
  Resolves given locator to all matching DOM elements.

  ## Returns

    - `[Playwright.ElementHandle.t()]`
  """
  @spec element_handles(t()) :: [ElementHandle.t()]
  def element_handles(locator) do
    Frame.query_selector_all(locator.frame, locator.selector)
  end

  @doc """
  Returns the result of executing `param: expression`.

  Passes the handle as the first argument to the expression.

  ## Returns

    - `Serializable.t()`

  ## Arguments

  | key/name   | type   |            | description |
  | ------------ | ------ | ---------- | ----------- |
  | `expression` | param  | `binary()` | JavaScript expression to be evaluated in the browser context. If it looks like a function declaration, it is interpreted as a function. Otherwise, evaluated as an expression. |
  | `arg`        | param  | `any()`    | Argument to pass to `expression` `(optional)` |
  | `:timeout`   | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec evaluate(t(), binary(), any(), options()) :: serializable()
  def evaluate(locator, expression, arg \\ nil, options \\ %{})

  require Logger

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

  @doc """
  Finds all elements matching the specified locator and passes the list of
  matched elements as an argument to `param: expression`.

  Returns the result of expression invocation.

  ## Returns

    - `Serializable.t()`

  ## Arguments

  | key/name   | type   |            | description |
  | ------------ | ------ | ---------- | ----------- |
  | `expression` | param  | `binary()` | JavaScript expression to be evaluated in the browser context. If it looks like a function declaration, it is interpreted as a function. Otherwise, evaluated as an expression. |
  | `arg`        | param  | `any()`    | Argument to pass to `expression` `(optional)` |
  """
  @spec evaluate_all(t(), binary(), any()) :: serializable()
  def evaluate_all(%Locator{} = locator, expression, arg \\ nil) do
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

    - `Playwright.ElementHandle.t()`
    - `{:error, Playwright.Channel.Error.t()}`

  ## Arguments

  | key/name   | type   |            | description |
  | ------------ | ------ | ---------- | ----------- |
  | `expression` | param  | `binary()` | JavaScript expression to be evaluated in the browser context. If it looks like a function declaration, it is interpreted as a function. Otherwise, evaluated as an expression. |
  | `arg`        | param  | `any()`    | Argument to pass to `expression` `(optional)` |
  | `:timeout`   | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec evaluate_handle(t(), binary(), any(), options()) :: ElementHandle.t() | {:error, Channel.Error.t()}
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

  | key/name       | type   |             | description |
  | ---------------- | ------ | ----------- | ----------- |
  | `value`          | param  | `binary()`  | Value to fill for the `<input>`, `<textarea>` or `[contenteditable]` element |
  | `:force`         | option | `boolean()` | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()` | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:timeout`       | option | `number()`  | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec fill(t(), binary(), options()) :: :ok
  def fill(%Locator{} = locator, value, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.fill(locator.frame, locator.selector, value, options)
  end

  @doc """
  Returns a new `Playwright.Locator` scoped to the first matching element.
  """
  @spec first(t()) :: Locator.t()
  def first(%Locator{} = context) do
    locator(context, "nth=0")
  end

  @doc """
  Calls [focus](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/focus) on the element.

  ## Returns

    - `:ok`

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec focus(t(), options()) :: :ok
  def focus(%Locator{} = locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.focus(locator.frame, locator.selector, options)
  end

  # ---

  # @spec frame_locator(t(), binary()) :: FrameLocator.t()
  # def frame_locator(locator, selector)

  # ---

  @doc """
  Returns element attribute value.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `name`     | param  | `binary()` | Name of the attribute to retrieve. |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec get_attribute(t(), binary(), options()) :: binary() | nil
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

  | key/name       | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `selector`       | param  | `binary()`                        | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:modifiers`     | option | `[:alt, :control, :meta, :shift]` | Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used. |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}`                   | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`                       | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec hover(t(), options()) :: :ok
  def hover(%Locator{} = locator, options \\ %{}) do
    Frame.hover(locator.frame, locator.selector, options)
  end

  @doc """
  Returns the `element.innerHTML`.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec inner_html(t(), options()) :: binary()
  def inner_html(%Locator{} = locator, options \\ %{}) do
    Frame.inner_html(locator.frame, locator.selector, options)
  end

  @doc """
  Returns the `element.innerText`.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec inner_text(t(), options()) :: binary()
  def inner_text(%Locator{} = locator, options \\ %{}) do
    Frame.inner_text(locator.frame, locator.selector, options)
  end

  @doc """
  Returns the `input.value`.

  Works on `<input>`, `<textarea>`, or `<select>` elements. Throws for
  non-input elements.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec input_value(t(), options()) :: binary()
  def input_value(%Locator{} = locator, options \\ %{}) do
    Frame.input_value(locator.frame, locator.selector, options)
  end

  @doc """
  Returns whether the element is checked.

  Throws if the element is not a checkbox or radio input.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec is_checked(t(), options()) :: boolean()
  def is_checked(%Locator{} = locator, options \\ %{}) do
    Frame.is_checked(locator.frame, locator.selector, options)
  end

  @doc """
  Returns whether the element is disabled.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec is_disabled(t(), options()) :: boolean()
  def is_disabled(%Locator{} = locator, options \\ %{}) do
    Frame.is_disabled(locator.frame, locator.selector, options)
  end

  @doc """
  Returns whether the element is editable.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec is_editable(t(), options()) :: boolean()
  def is_editable(%Locator{} = locator, options \\ %{}) do
    Frame.is_editable(locator.frame, locator.selector, options)
  end

  @doc """
  Returns whether the element is enabled.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec is_enabled(t(), options()) :: boolean()
  def is_enabled(%Locator{} = locator, options \\ %{}) do
    Frame.is_enabled(locator.frame, locator.selector, options)
  end

  @doc """
  Returns whether the element is hidden.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec is_hidden(t(), options()) :: boolean()
  def is_hidden(%Locator{} = locator, options \\ %{}) do
    Frame.is_hidden(locator.frame, locator.selector, options)
  end

  @doc """
  Returns whether the element is visible.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec is_visible(t(), options()) :: boolean()
  def is_visible(%Locator{} = locator, options \\ %{}) do
    Frame.is_visible(locator.frame, locator.selector, options)
  end

  @doc """
  Returns a new `Playwright.Locator` scoped to the last matching element.
  """
  @spec last(t()) :: Locator.t()
  def last(%Locator{} = context) do
    locator(context, "nth=-1")
  end

  @doc """
  Returns a new `Playwright.Locator` scoped to the Locator's subtree.
  """
  @spec locator(t(), binary()) :: Locator.t()
  def locator(%Locator{} = locator, selector) do
    Locator.new(locator.frame, "#{locator.selector} >> #{selector}")
  end

  @doc """
  Returns a new `Playwright.Locator` scoped to the n-th matching element.
  """
  @spec nth(t(), term()) :: Locator.t()
  def nth(%Locator{} = context, index) do
    locator(context, "nth=#{index}")
  end

  @doc """
  Focuses the element, and then uses `keyboard.down(key)` and `keyboard.up(key)`.

  `param: key` can specify the intended [keyboardEvent.key](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key)
  value or a single character. A superset of the key values can be found [on MDN](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values).

  Examples of the keys are:

  - `F1` - `F12`
  - `Digit0` - `Digit9`
  - `KeyA` - `KeyZ`
  - `Backquote`
  - `Minus`
  - `Equal`
  - `Backslash`
  - `Backspace`
  - `Tab`
  - `Delete`
  - `Escape`
  - `ArrowDown`
  - `End`
  - `Enter`
  - `Home`
  - `Insert`
  - `PageDown`
  - `PageUp`
  - `ArrowRight`
  - `ArrowUp`

  The fllowing modification shortcuts are also supported:

  - `Shift`
  - `Control`
  - `Alt`
  - `Meta`
  - `ShiftLeft`

  Holding down `Shift` will type the text that corresponds to the `param: key`
  in the upper case.

  If `param: key` is a single character, it is case-sensitive, so the values
  `a` and `A` will generate different respective texts.

  Shortcuts such as `key: "Control+o"` or `key: "Control+Shift+T"` are
  supported as well. When specified with the modifier, modifier is pressed
  and held while the subsequent key is pressed.

  ## Arguments

  | key/name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `key`            | param  | `binary()`      | Name of the key to press or a character to generate, such as `ArrowLeft` or `a`. |
  | `:delay`         | option | `number()`      | Time to wait between `mousedown` and `mouseup` in milliseconds. `(default: 0)` |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec press(t(), binary(), options_keyboard()) :: :ok
  def press(%Locator{} = locator, key, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.press(locator.frame, locator.selector, key, options)
  end

  @doc """
  Returns a buffer with the captured screenshot data.

  Waits for the actionability checks, then scrolls element into view before
  taking a screenshot. If the element is detached from DOM, throws an error.

  ## Arguments

  | key/name         | type   |                   | description |
  | ------------------ | ------ | ----------------- | ----------- |
  | `:omit_background` | option | `boolean()`       | Hides default white background and allows capturing screenshots with transparency. Not applicable to jpeg images. `(default: false)` |
  | `:path`            | option | `binary()`        | The file path to which to save the image. The screenshot type will be inferred from file extension. If path is a relative path, then it is resolved relative to the current working directory. If no path is provided, the image won't be saved to the disk. |
  | `:quality`         | option | `number()`        | The quality of the image, between 0-100. Not applicable to `png` images. |
  | `:timeout`         | option | `number()`        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  | `:type`            | option | `:png` or `:jpeg` | Specify screenshot type. `(default: :png)` |
  """
  @spec screenshot(t(), options()) :: binary()
  def screenshot(%Locator{} = locator, options \\ %{}) do
    with_element(locator, options, fn handle ->
      ElementHandle.screenshot(handle, options)
    end)
  end

  @doc """
  Waits for actionability checks, then tries to scroll element into view,
  unless it is completely visible as defined by [IntersectionObserver](https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API)'s
  ratio.

  ## Arguments

  | key/name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec scroll_into_view(t(), options()) :: :ok
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
      alias Playwright.Locator
      locator = Locator.new(page, "select#colors")

      # single selection matching the value
      Locator.select_option(locator, "blue")

      # single selection matching both the label
      Locator.select_option(locator, %{label: "blue"})

      # multiple selection
      Locator.select_option(locator, %{value: ["red", "green", "blue"]})

  ## Returns

    - `[binary()]`

  ## Arguments

  | key/name       | type   |                 | description |
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
  @spec select_option(t(), any(), options()) :: [binary()]
  def select_option(%Locator{} = locator, values, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.select_option(locator.frame, locator.selector, values, options)
  end

  @doc """
  Waits for actionability checks, then focuses the element and selects all its
  text content.

  ## Arguments

  | key/name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `:force`         | option | `boolean()`     | Whether to bypass the actionability checks. `(default: false)` |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec select_text(t(), options()) :: :ok
  def select_text(%Locator{} = locator, options \\ %{}) do
    with_element(locator, options, fn handle ->
      ElementHandle.select_text(handle, options)
    end)
  end

  @doc """
  Checks or unchecks an element.

  Performs the following steps and checks:

    1. Ensure that the matched element is a checkbox or a radio input. If not,
      the call throws.
    2. If the element already has the right checked state, returns immediately.
    3. Wait for actionability checks on the matched element, unless
      `option: force` is set. If the element is detached during the checks, the
      whole action is retried.
    4. Scroll the element into view if needed.
    5. Use `Page.Mouse` to click in the center of the element.
    6. Wait for initiated navigations to either succeed or fail, unless
      `option: no_wait_after` is set.
    7. Ensure that the element is now checked or unchecked.
      If not, the call throws.

  When all steps combined have not finished during the specified timeout,
  throws a `TimeoutError`. Passing `0` timeout disables this.

  ## Arguments

  | key/name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `checked`        | param  | `boolean()`     | Whether to check or uncheck the checkbox. |
  | `:force`         | option | `boolean()`     | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}` | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`     | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec set_checked(t(), boolean(), options()) :: :ok
  def set_checked(%Locator{} = locator, checked, options \\ %{}) do
    if checked do
      check(locator, options)
    else
      uncheck(locator, options)
    end
  end

  @doc """
  Sets the value of the file input to these file paths or files.

  If some of the file paths are relative paths, they are resolved relative to
  the the current working directory. An empty list, clears the selected files.

  Expects element (i.e., `locator.selector`) to point to an input element.

  ## Arguments

  | key/name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `files`          | param  | `any()`         | ... |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec set_input_files(t(), any(), options()) :: :ok
  def set_input_files(%Locator{} = locator, files, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.set_input_files(locator.frame, locator.selector, files, options)
  end

  @doc """
  Returns a string representation of the `Playwright.Locator`.
  """
  @spec string(t()) :: binary()
  def string(%Locator{} = locator) do
    "Locator@#{locator.selector}"
  end

  @doc """
  Taps the element (i.e., mimicking trackpad input).

  Performs the following steps:

    1. Wait for actionability checks on the element, unless `option: force`
      is set.
    2. Scroll the element into view if needed.
    3. Use `Page.Touchscreen` to tap the center of the element, or the
      specified position.
    4. Wait for initiated navigations to either succeed or fail, unless
      `option: no_wait_after` is set.

  If the element is detached from the DOM at any moment during the action,
  throws an error.

  When all steps combined have not finished during the specified timeout,
  throws a `TimeoutError`. Passing `0` timeout disables this.

  > NOTE:
  >
  > `tap/2` requires that the `:has_touch` option of the browser context be
  > set to `true`.

  ## Arguments

  | key/name       | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:modifiers`     | option | `[:alt, :control, :meta, :shift]` | Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used. |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}`                   | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`                       | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec tap(t(), options()) :: :ok
  def tap(locator, options \\ %{}) do
    options = Map.merge(options, %{strict: true})
    Frame.tap(locator.frame, locator.selector, options)
  end

  @doc """
  Returns the `node.textContent`.

  ## Arguments

  | key/name | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `:timeout` | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec text_content(t(), options()) :: binary()
  def text_content(%Locator{} = locator, options \\ %{}) do
    Frame.text_content(locator.frame, locator.selector, options)
  end

  @doc """
  Focuses the element, and then sends a `keydown`, `keypress/input`, and
  `keyup` event for each character in the text.

  To press a special key, like `Control` or `ArrowDown`, use
  `Playwright.Locator.press/3`.

  ## Arguments

  | key/name       | type   |             | description |
  | ---------------- | ------ | ----------- | ----------- |
  | `text`           | param  | `binary()`  | Text to type into a focused element. |
  | `:delay`         | option | `number()`  | Time to wait between `mousedown` and `mouseup` in milliseconds. `(default: 0)` |
  | `:no_wait_after` | option | `boolean()` | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:timeout`       | option | `number()`  | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  """
  @spec type(t(), binary(), options_keyboard()) :: :ok
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

  | key/name       | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `:force`         | option | `boolean()`     | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}` | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:timeout`       | option | `number()`      | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`     | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec uncheck(t(), options()) :: :ok
  def uncheck(%Locator{} = locator, options \\ %{}) do
    Frame.uncheck(locator.frame, locator.selector, options)
  end

  @doc """
  Returns when element specified by locator satisfies `option: state`.

  If target element already satisfies the condition, the method returns
  immediately. Otherwise, waits for up to `option: timeout` milliseconds until
  the condition is met.

  ## Options

  | key/name   | type   |              | description |
  | ---------- | ------ | ------------ | ----------- |
  | `:state`   | option | state option | Defaults to `visible`. See "state options" below" |
  | `:timeout` | option | float        | Maximum time in milliseconds, defaults to 30 seconds, pass 0 to disable timeout. The default value can be changed by using the browser_context.set_default_timeout(timeout) or page.set_default_timeout(timeout) methods. |

  ## State options

  | value      | description |
  | ---------- | ----------- |
  | 'attached' | wait for element to be present in DOM. |
  | 'detached' | wait for element to not be present in DOM. |
  | 'visible'  | wait for element to have non-empty bounding box and no visibility:hidden. Note that element without any content or with display:none has an empty bounding box and is not considered visible. |
  | 'hidden'   | wait for element to be either detached from DOM, or have an empty bounding box or visibility:hidden. This is opposite to the 'visible' option. |
  """
  @spec wait_for(t(), options()) :: :ok
  def wait_for(%Locator{} = locator, options \\ %{}) do
    Frame.wait_for_selector(locator.frame, locator.selector, options)
    :ok
  end

  # private
  # ---------------------------------------------------------------------------

  defp with_element(%Locator{frame: frame} = locator, options, task) do
    params = Map.merge(options, %{selector: locator.selector})

    case Channel.post(frame.session, {:guid, frame.guid}, :wait_for_selector, params) do
      %ElementHandle{} = handle ->
        task.(handle)

      {:error, _} = error ->
        error
    end
  end
end
