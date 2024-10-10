defmodule Playwright.Frame do
  @moduledoc """
  At any point of time, `Playwright.Page` exposes its current frame tree via
  the `Playwright.Page.main_frame/1` and `Playwright.Frame.child_frames/1`
  functions.

  A `Frame` instance lifecycle is governed by three events, dispatched on the
  `Playwright.Page` resource:

    - `Page event: :frame_attached` - fired when the frame gets attached to the
      page. A Frame can be attached to the page only once.
    - `Page event: :frame_navigated` - fired when the frame commits navigation
      to a different URL.
    - `Page event: :frame_detached` - fired when the frame gets detached from
      the page.  A Frame can be detached from the page only once.
  """
  use Playwright.SDK.ChannelOwner
  alias Playwright.{ElementHandle, Frame, Locator, Response}
  alias Playwright.API.Error
  alias Playwright.SDK.{ChannelOwner, Helpers}

  @property :load_states
  @property :url

  @type evaluation_argument :: any()
  @type expression :: binary()
  @type options :: map()
  @type serializable :: any()
  @type load_state :: atom() | binary()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%Frame{} = frame, _initializer) do
    Channel.bind(frame.session, {:guid, frame.guid}, :loadstate, fn %{params: params} = event ->
      target = event.target

      case params do
        %{add: state} ->
          {:patch, %{target | load_states: target.load_states ++ [state]}}

        %{remove: state} ->
          {:patch, %{target | load_states: target.load_states -- [state]}}
      end
    end)

    Channel.bind(frame.session, {:guid, frame.guid}, :navigated, fn event ->
      {:patch, %{event.target | url: event.params.url}}
    end)

    {:ok, frame}
  end

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec add_script_tag(Frame.t(), options()) :: ElementHandle.t() | {:error, Error.t()}
  # def add_script_tag(frame, options \\ %{})

  # @spec add_style_tag(Frame.t(), options()) :: ElementHandle.t() | {:error, Error.t()}
  # def add_style_tag(frame, options \\ %{})

  # ---

  @spec check(t(), binary(), options()) :: t() | {:error, Error.t()}
  def check(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :check}, %{selector: selector}, options)
  end

  # ---

  # @spec child_frames(Frame.t()) :: [Frame.t()] | {:error, Error.t()}
  # def child_frames(frame)

  # ---

  @doc """
  Clicks an element matching `param: selector`, performing the following steps:

    1. Find an element matching `param: selector`. If there is none, wait until
      a matching element is attached to the DOM.
    2. Wait for "actionability (guide)" checks on the matched element, unless
      `option: force` option is set. If the element is detached during the
      checks, the whole action is retried.
    3. Scroll the element into view if needed.
    4. Use `Playwright.Page.Mouse` to click the center of the element, or the
      specified `option: position`.
    5. Wait for initiated navigations to either succeed or fail, unless
      `option: :no_wait_after` option is set.

  When all steps combined have not finished during the specified
  `option: timeout`, `/click/3` raises a `TimeoutError`. Passing zero for
  `option: timeout` disables this.
  """
  @spec click(t(), binary(), options()) :: t() | {:error, Error.t()}
  def click(frame, selector, options \\ %{})

  def click(%Frame{} = frame, selector, options) do
    Channel.post(
      {frame, :click},
      %{
        selector: selector,
        timeout: 30_000,
        wait_until: "load"
      },
      options
    )
  end

  # ---

  @spec content(Frame.t()) :: binary() | {:error, Error.t()}
  def content(%Frame{} = frame) do
    Channel.post({frame, :content})
  end

  # ---

  @doc """
  Double clicks an element matching selector.

  Performs the following steps:

    1. Find an element matching `param: selector`. If there is none, wait until
      a matching element is attached to the DOM.
    2. Wait for actionability checks on the matched element, unless
      `option: force` is set. If the element is detached during the checks, the
      whole action is retried.
    3. Scroll the element into view if needed.
    4. Use `Page.Mouse` to double click in the center of the element, or the
      specified `option: position`.
    5. Wait for initiated navigations to either succeed or fail, unless
      `option: no_wait_after` is set. Note that if the first click of the
      `dblclick/3` triggers a navigation event, the call will throw.

  When all steps combined have not finished during the specified
  `option: timeout`, throws a `TimeoutError`. Passing `timeout: 0` disables
  this.

  > NOTE
  >
  > `dblclick/3` dispatches two `click` events and a single `dblclick` event.

  ## Returns

    - `t()`
    - `{:error, Error.t()}`

  ## Arguments

  | key/name         | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `selector`       | param  | `binary()`                        | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:button`        | option | `:left`, `:right` or `:middle`    | `(default: :left)` |
  | `:delay`         | option | `number() `                       | Time to wait between keydown and keyup in milliseconds. `(default: 0)` |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:modifiers`     | option | `[:alt, :control, :meta, :shift]` | Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used. |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}`                   | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:strict`        | option | `boolean()`                       | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`                       | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec dblclick(Frame.t(), binary(), options()) :: t() | {:error, Error.t()}
  def dblclick(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :dblclick}, %{selector: selector}, options)
  end

  @doc """
  Dispatches the `param: type` event on the `param: selector` element.

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

      Frame.dispatch_event(frame, "button#submit", :click)

  Specify a `Playwright.JSHandle` as the property value to be passed into the
  event:

      data_transfer = Frame.evaluate_handle(frame, "new DataTransfer()")
      Frame.dispatch_event(frame, "#source", :dragstart, { "dataTransfer": data_transfer })

  ## Returns

  - `t()`
  - `{:error, Error.t()}`

  ## Arguments

  | key/name         | type   |                         | description |
  | ---------------- | ------ | ----------------------- | ----------- |
  | `selector`       | param  | `binary()`              | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `type`           | param  | `atom()` or `binary()`  | DOM event type: `:click`, `:dragstart`, etc. |
  | `event_init`     | param  | `evaluation_argument()` | Optional event-specific initialization properties. |
  | `:strict`        | option | `boolean()`             | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout`       | option | `number()`              | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec dispatch_event(Frame.t(), binary(), binary(), evaluation_argument(), options()) :: t() | {:error, Error.t()}
  def dispatch_event(frame, selector, type, event_init \\ nil, options \\ %{})

  def dispatch_event(%Frame{} = frame, selector, type, options, _)
      when is_map(options) do
    dispatch_event(frame, selector, type, nil, options)
  end

  def dispatch_event(%Frame{} = frame, selector, type, event_init, options) do
    Channel.post(
      {frame, :dispatch_event},
      %{
        selector: selector,
        type: type,
        event_init: serialize(event_init)
      },
      options
    )
  end

  # ---

  @spec drag_and_drop(Frame.t(), binary(), binary(), options()) :: t() | {:error, Error.t()}
  def drag_and_drop(frame, source, target, options \\ %{}) do
    Channel.post({frame, :drag_and_drop}, %{source: source, target: target}, options)
  end

  # @spec eval_on_selector(Frame.t(), binary(), expression(), any(), options()) :: ...
  # def eval_on_selector(frame, selector, expression, arg \\ nil, options \\ %{})

  # @spec eval_on_selector_all(Frame.t(), binary(), expression(), any(), options()) :: ...
  # def eval_on_selector_all(frame, selector, expression, arg \\ nil, options \\ %{})

  # ---

  @doc """
  Returns the return value of `expression`.

  !!!
  """
  @spec eval_on_selector(Frame.t(), binary(), binary(), term(), map()) :: term() | {:error, Error.t()}
  def eval_on_selector(frame, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Frame{} = frame, selector, expression, arg, _options) do
    parse_result(fn ->
      Channel.post({frame, :eval_on_selector}, %{
        selector: selector,
        expression: expression,
        arg: serialize(arg)
      })
    end)
  end

  def eval_on_selector_all(%Frame{} = frame, selector, expression, arg \\ nil) do
    parse_result(fn ->
      Channel.post(
        {frame, :eval_on_selector_all},
        %{
          selector: selector,
          expression: expression,
          arg: serialize(arg)
        }
      )
    end)
  end

  @doc """
  Returns the return value of `expression`.
  !!!
  """
  @spec evaluate(t(), expression(), any()) :: term() | {:error, Error.t()}
  def evaluate(owner, expression, arg \\ nil)

  def evaluate(%Frame{} = frame, expression, arg) do
    parse_result(fn ->
      Channel.post(
        {frame, :evaluate_expression},
        %{
          expression: expression,
          is_function: Helpers.Expression.function?(expression),
          arg: serialize(arg)
        }
      )
    end)
  end

  @doc """
  Returns the return value of `expression` as a `Playwright.JSHandle`.
  !!!
  """
  @spec evaluate_handle(t(), expression(), any()) :: serializable() | {:error, Error.t()}
  def evaluate_handle(%Frame{} = frame, expression, arg \\ nil) do
    Channel.post(
      {frame, :evaluate_expression_handle},
      %{
        expression: expression,
        is_function: Helpers.Expression.function?(expression),
        arg: serialize(arg)
      },
      %{refresh: false}
    )
  end

  # ---

  # @spec expect_navigation(Frame.t(), function(), options()) :: ...
  # def expect_navigation(frame, trigger, options \\ %{})

  # ---

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
  > - To send fine-grained keyboard events, use `Playwright.Frame.type/4`.

  ## Returns

    - `t()`
    - `{:error, Error.t()}`

  ## Arguments

  | key/name         | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `selector`       | param  | `binary()`                        | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `value`          | param  | `binary()`                        | Value to fill for the `<input>`, `<textarea>` or `[contenteditable]` element |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:strict`        | option | `boolean()`                       | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec fill(t(), binary(), binary(), options()) :: t() | {:error, Error.t()}
  def fill(%Frame{} = frame, selector, value, options \\ %{}) do
    Channel.post({frame, :fill}, %{selector: selector, value: value}, options)
  end

  # ---

  @doc """
  Fetches an element with `param: selector` and focuses it.

  If no element matches the selector, waits until a matching element appears in the DOM.

  ## Returns

    - `t()`
    - `{:error, Error.t()}`

  ## Arguments

  | key/name   | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:strict`  | option | `boolean()` | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout` | option | `number()`  | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec focus(t(), binary(), options()) :: t() | {:error, Error.t()}
  def focus(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :focus}, %{selector: selector}, options)
  end

  # @spec frame_element(Frame.t()) :: ElementHandle.t()
  # def frame_element(frame)

  # @spec frame_locator(Frame.t(), binary()) :: FrameLocator.t()
  # def frame_locator(frame, selector)

  # ---

  @doc """
  Returns element attribute value.
  !!!
  """
  @spec get_attribute(t(), binary(), binary(), map()) :: binary() | {:error, Error.t()}
  def get_attribute(%Frame{} = frame, selector, name, options \\ %{}) do
    Channel.post(
      {frame, :get_attribute},
      %{
        selector: selector,
        name: name
      },
      options
    )
  end

  # @spec get_by_alt_text(Frame.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_alt_text(frame, text, options \\ %{})

  # @spec get_by_label(Frame.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_label(frame, text, options \\ %{})

  # @spec get_by_placeholder(Frame.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_placeholder(frame, text, options \\ %{})

  # @spec get_by_role(Frame.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_role(frame, text, options \\ %{})

  # @spec get_by_test_id(Frame.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_test_id(frame, text, options \\ %{})

  @doc """
  Allows locating elements that contain given text.

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `text`     | param  | `binary()` | Text to locate the element for. |
  | `:exact`   | option | `boolean()`| Whether to find an exact match: case-sensitive and whole-string. Default to false. Ignored when locating by a regular expression. Note that exact match still trims whitespace. |
  """
  @spec get_by_text(Frame.t(), binary(), %{optional(:exact) => boolean()}) :: Playwright.Locator.t() | nil
  def get_by_text(frame, text, options \\ %{}) do
    locator(frame, Locator.get_by_text_selector(text, options))
  end

  # @spec get_by_title(Frame.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_title(frame, text, options \\ %{})

  @doc """
  !!!
  """
  @spec goto(t(), binary(), options()) :: Response.t() | nil | {:error, Error.t()}
  def goto(frame, url, options \\ %{})

  def goto(%Frame{} = frame, url, options) do
    params = Map.merge(options, %{url: url})
    Channel.post({frame, :goto}, params)
  end

  @doc """
  Hovers over an element matching `param: selector`.

  Performs the following steps:

  1. Find an element matching `param: selector`. If there is none, wait until
    a matching element is attached to the DOM.
  2. Wait for actionability checks on the matched element, unless
    `option: force` option is set. If the element is detached during the checks,
    the whole action is retried.
  3. Scroll the element into view if needed.
  4. Use `Page.Mouse` to hover over the center of the element, or the specified
    `option: position`.
  5. Wait for initiated navigations to either succeed or fail, unless
    `option: no_wait_after` is set.

  When all steps combined have not finished during the specified `option: timeout`,
  throws a `TimeoutError`. Passing `0` timeout disables this.

  ## Returns

    - `:ok`

  ## Arguments

  | key/name         | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `selector`       | param  | `binary()`                        | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:modifiers`     | option | `[:alt, :control, :meta, :shift]` | Modifier keys to press. Ensures that only these modifiers are pressed during the operation, and then restores current modifiers back. If not specified, currently pressed modifiers are used. |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:position`      | option | `%{x: x, y: y}`                   | A point to use relative to the top-left corner of element padding box. If not specified, uses some visible point of the element. |
  | `:strict`        | option | `boolean()`                       | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  | `:trial`         | option | `boolean()`                       | When set, this call only performs the actionability checks and skips the action. Useful to wait until the element is ready for the action without performing it. `(default: false)` |
  """
  @spec hover(Frame.t(), binary(), options()) :: t() | {:error, Error.t()}
  def hover(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :hover}, %{selector: selector}, options)
  end

  @spec inner_html(Frame.t(), binary(), options()) :: binary() | {:error, Error.t()}
  def inner_html(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, "innerHTML"}, %{selector: selector}, options)
  end

  @spec inner_text(Frame.t(), binary(), options()) :: binary() | {:error, Error.t()}
  def inner_text(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :inner_text}, %{selector: selector}, options)
  end

  @spec input_value(Frame.t(), binary(), options()) :: binary() | {:error, Error.t()}
  def input_value(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :input_value}, %{selector: selector}, options)
  end

  @spec is_checked(Frame.t(), binary(), options()) :: boolean() | {:error, Error.t()}
  def is_checked(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :is_checked}, %{selector: selector}, options)
  end

  # @spec is_detached(Frame.t(), binary(), options()) :: boolean() | {:error, Error.t()}
  # def is_detached(frame, selector, options \\ %{})

  @spec is_disabled(Frame.t(), binary(), options()) :: boolean() | {:error, Error.t()}
  def is_disabled(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :is_disabled}, %{selector: selector}, options)
  end

  @spec is_editable(Frame.t(), binary(), options()) :: boolean() | {:error, Error.t()}
  def is_editable(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :is_editable}, %{selector: selector}, options)
  end

  @spec is_enabled(Frame.t(), binary(), options()) :: boolean() | {:error, Error.t()}
  def is_enabled(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :is_enabled}, %{selector: selector}, options)
  end

  @spec is_hidden(Frame.t(), binary(), options()) :: boolean() | {:error, Error.t()}
  def is_hidden(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :is_hidden}, %{selector: selector}, options)
  end

  @spec is_visible(Frame.t(), binary(), options()) :: boolean() | {:error, Error.t()}
  def is_visible(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :is_visible}, %{selector: selector}, options)
  end

  # ---

  @spec locator(Frame.t(), binary()) :: Playwright.Locator.t()
  def locator(frame, selector) do
    Playwright.Locator.new(frame, selector)
  end

  # @spec name(Frame.t()) :: binary()
  # def name(frame)

  # @spec page(Frame.t()) :: Page.t()
  # def page(frame)

  # @spec parent_frame(Frame.t()) :: Frame.t()
  # def parent_frame(frame)

  # ??? is it `parent_frame` now, instead?
  # @spec parent_page(Frame.t()) :: Frame.t()
  # def parent_page(frame)

  # ---

  @doc """
  `param: key` can specify the intended [`keyboardEvent.key`](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key)
  value or a single character for which to generate the text.

  A superset of the
  `param: key` values can be found on [MDN](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values).

  Examples of the keys are:

  `F1` - `F12`, `Digit0`- `Digit9`, `KeyA`- `KeyZ`, `Backquote`, `Minus`,
  `Equal`, `Backslash`, `Backspace`, `Tab`, `Delete`, `Escape`, `ArrowDown`,
  `End`, `Enter`, `Home`, `Insert`, `PageDown`, `PageUp`, `ArrowRight`,
  `ArrowUp`, etc.

  The following modification shortcuts are also supported: `Shift`, `Control`,
  `Alt`, `Meta`, `ShiftLeft`.

  Holding down `Shift` will type the text that corresponds to the `param: key`
  in the upper case.

  If `param: key` is a single character, it is case-sensitive, so the values
  `a` and `A` will generate different respective texts.

  Shortcuts such as `key: "Control+o"` or `key: "Control+Shift+T"` are
  supported as well. When specified with the modifier, modifier is pressed
  and being held while the subsequent key is being pressed.

  ## Returns

    - `t()`
    - `{:error, Error.t()}`

  ## Arguments

  | key/name         | type   |              | description |
  | ---------------- | ------ | ------------ | ----------- |
  | `selector`       | param  | `binary()`   | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `key`            | param  | `binary()`   | Name of the key to press or a character to generate, such as `ArrowLeft` or `a`. |
  | `:delay`         | option | `number() `  | Time to wait between keydown and keyup in milliseconds. `(default: 0)` |
  | `:no_wait_after` | option | `boolean()`  | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:strict`        | option | `boolean()`  | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout`       | option | `number()`   | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec press(t(), binary(), binary(), options()) :: t() | {:error, Error.t()}
  def press(%Frame{} = frame, selector, key, options \\ %{}) do
    Channel.post({frame, :press}, %{selector: selector, key: key}, options)
  end

  # 20240807: Official implementations define (something similar to) this as
  # a pseudo-private function/method. As such, our implementation is hidden
  # from documentation for the time being. Only called from `Locator.count/1`.
  # ---
  @doc false
  @spec query_count(t(), binary()) :: number()
  def query_count(%Frame{} = frame, selector) do
    Channel.post({frame, :query_count}, %{selector: selector})
  end

  @doc """
  Returns the `Playwright.ElementHandle` pointing to the frame element.

  The function finds an element matching the specified selector within the
  frame. See "working with selectors (guide)" for more details. If no elements
  match the selector, returns `nil`.

  ## Returns

    - `Playwright.ElementHandle.t()`
    - `nil`
    - `{:error, :timeout}`

  ## Arguments

  | key/name   | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to query for. See "working with selectors (guide)" for more details. |
  | `strict`   | option | `boolean()` | When true, the call requires `selector` to resolve to a single element. If the given `selector` resolves to more then one element, the call raises an error. |
  """
  @spec query_selector(t(), binary(), map()) :: ElementHandle.t() | nil | {:error, :timeout}
  def query_selector(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :query_selector}, %{selector: selector}, options)
  end

  defdelegate q(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector

  @doc """
  Returns the list of `Playwright.ElementHandle` pointing to the frame elements.

  The method finds all elements matching the specified selector within the
  frame. See "working with selectors (guide)" for more details.

  If no elements match the selector, returns an empty `List`.

  ## Returns

    - `[Playwright.ElementHandle.t()]`
    - `{:error, Error.t()}`

  ## Arguments

  | key/name   | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to query for. See "working with selectors (guide)" for more details. |
  """
  @spec query_selector_all(t(), binary(), map()) :: [ElementHandle.t()] | {:error, Error.t()}
  def query_selector_all(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :query_selector_all}, %{selector: selector}, options)
  end

  defdelegate qq(frame, selector, options \\ %{}), to: __MODULE__, as: :query_selector_all

  @doc """
  Selects one or more options from a `<select>` element.

  Performs the following steps:

  1. Waits for an element matching `param: selector`
  2. Waits for actionability checks
  3. Waits until all specified options are present in the `<select>` element
  4. Selects those options

  If the target element is not a `<select>` element, raises an error. However,
  if the element is inside the `<label>` element that has an associated control,
  the control will be used instead.

  Returns the list of option values that have been successfully selected.

  Triggers a change and input event once all the provided options have been selected.

  ## Example

      # single selection matching the value
      Frame.select_option(frame, "select#colors", "blue")

      # single selection matching both the label
      Frame.select_option(frame, "select#colors", %{label: "blue"})

      # multiple selection
      Frame.select_option(frame, "select#colors", %{value: ["red", "green", "blue"]})

  ## Returns

    - `[binary()]`
    - `{:error, Error.t()}`

  ## Arguments

  | key/name         | type   |                 | description |
  | ---------------- | ------ | --------------- | ----------- |
  | `selector`       | param  | `binary()`      | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `values`         | param  | `any()`         | Options to select. |
  | `:force`         | option | `boolean()`     | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`     | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:strict`        | option | `boolean()`     | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
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
  @spec select_option(Frame.t(), binary(), any(), options()) :: [binary()] | {:error, Error.t()}
  def select_option(%Frame{} = frame, selector, values, options \\ %{}) do
    Channel.post({frame, :select_option}, Map.merge(select_option_values(values), %{selector: selector}), options)
  end

  # ---

  # @spec set_checked(Frame.t(), boolean(), options()) :: t() | {:error, Error.t()}
  # def set_checked(frame, checked, options \\ %{})

  # ---

  @doc """
  ## Returns

    - `t()`
    - `{:error, Error.t()}`

  ## Arguments

  | key/name   | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `html`     | param  | `binary()`  | HTML markup to assign to the page. |
  | `:timeout` | option | `number()`  | Maximum operation time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_navigation_timeout/2`, `Playwright.BrowserContext.set_default_timeout/2`, `Playwright.Page.set_default_navigation_timeout/2` or `Playwright.Page.set_default_timeout/` functions. `(default: 30 seconds)` |
  """
  @spec set_content(t(), binary(), options()) :: t() | {:error, Error.t()}
  def set_content(%Frame{} = frame, html, options \\ %{}) do
    Channel.post({frame, :set_content}, %{html: html, timeout: 30_000, wait_until: "load"}, options)
  end

  # **NOTE:**
  # Of `payloads`, `local_paths`, and `streams` playwright-core capabilities,
  # only `local_paths` is currently supported by playwright-elixir.
  @spec set_input_files(Frame.t(), binary(), any(), options()) :: t() | {:error, Error.t()}
  def set_input_files(%Frame{} = frame, selector, files, options \\ %{}) do
    Channel.post(
      {frame, :set_input_files},
      %{
        selector: selector,
        local_paths: normalize_file_payloads(files)
      },
      options
    )
  end

  @spec tap(Frame.t(), binary(), options()) :: t() | {:error, Error.t()}
  def tap(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :tap}, %{selector: selector}, options)
  end

  @doc """
  Returns `Playwright.ElementHandle.text_content/1`

  ## Returns

    - `binary()`
    - `nil`

  ## Arguments

  | key/name   | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:strict`  | option | `boolean()` | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout` | option | `number()`  | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec text_content(t(), binary(), map()) :: binary() | nil
  def text_content(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :text_content}, %{selector: selector}, options)
  end

  @doc """
  Returns the page title.

  ## Returns

    - `binary()`
  """
  @spec title(t()) :: binary()
  def title(%Frame{} = frame) do
    Channel.post({frame, :title})
  end

  @spec type(Frame.t(), binary(), binary(), options()) :: t() | {:error, Error.t()}
  def type(%Frame{} = frame, selector, text, options \\ %{}) do
    Channel.post({frame, :type}, %{selector: selector, text: text}, options)
  end

  @spec uncheck(t(), binary(), options()) :: t() | {:error, Error.t()}
  def uncheck(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :uncheck}, %{selector: selector}, options)
  end

  # ---

  # @spec url(Frame.t()) :: binary()
  # def url(frame)

  # @spec wait_for_function(Frame.t(), expression(), any(), options()) :: JSHandle.t()
  # def wait_for_function(frame, expression, arg \\ nil, options \\ %{})

  # ---

  @doc """
  Waits for the required load state to be reached.

  This returns when the frame reaches a required load state, "load" by default.
  The navigation must have been committed when this method is called. If
  the current document has already reached the required state, resolves
  immediately.
  """
  @spec wait_for_load_state(Frame.t(), binary(), options()) :: Frame.t()
  def wait_for_load_state(frame, state \\ "load", options \\ %{})

  def wait_for_load_state(%Frame{} = frame, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    if Enum.member?(frame.load_states, state) do
      frame
    else
      # e = Channel.wait_for(frame, :loadstate)
      {:ok, e} = Channel.wait(frame.session, {:guid, frame.guid}, :loadstate)
      e.target
    end
  end

  # def wait_for_load_state(%Frame{} = frame, state, options) when is_binary(state) do
  #   wait_for_load_state(frame, state, options)
  # end

  # def wait_for_load_state(%Frame{} = frame, options, _) when is_map(options) do
  #   wait_for_load_state(frame, "load", options)
  # end

  # ---

  # @spec wait_for_navigation(Frame.t(), options()) :: :ok
  # def wait_for_navigation(frame, options \\ %{})

  # ---

  @doc """
  Returns when element specified by selector satisfies state option.

  FIXME: the following is NOT TRUE... Returns `nil` if waiting for a hidden or detached element.
  """
  @spec wait_for_selector(t(), binary(), map()) :: ElementHandle.t() | {:error, Error.t()}
  def wait_for_selector(%Frame{} = frame, selector, options \\ %{}) do
    Channel.post({frame, :wait_for_selector}, %{selector: selector}, options)
  end

  # ---

  # @spec wait_for_timeout(Frame.t(), number()) :: :ok
  # def wait_for_timeout(frame, timeout)

  # @spec wait_for_url(Frame.t(), binary(), options()) :: :ok
  # def wait_for_url(frame, url, options \\ %{})

  # ---

  # private
  # ---------------------------------------------------------------------------

  defp normalize_file_payloads(files) when is_binary(files) do
    normalize_file_payloads([files])
  end

  defp normalize_file_payloads(files) when is_list(files) do
    Enum.into(files, [], fn file ->
      normalize_file_payload(file)
    end)
  end

  defp normalize_file_payload(file) when is_binary(file) do
    Path.expand(file)

    # NOTE: will need to re-introduce something similar to what follows when
    # we add support for the `payloads` and `streams` approaches.
    # {:ok, data} = File.read(file)

    # %{
    #   name: Path.basename(file),
    #   buffer: Base.encode64(data)
    # }
  end

  # when it's a `FilePayload`...
  # defp normalize_file_payload(file) do
  #   %{
  #     name: file.name,
  #     mime_type: file.mime_type,
  #     buffer: Base.encode64(file.buffer)
  #   }
  # end

  defp parse_result(task) when is_function(task) do
    task.() |> Helpers.Serialization.deserialize()
  end

  # NOTE: these might all want to move to ElementHandle
  defp select_option_values(values) when is_nil(values) do
    %{}
  end

  defp select_option_values(values) when not is_list(values) do
    select_option_values([values])
  end

  defp select_option_values(values) when is_list(values) do
    if Enum.empty?(values) do
      %{}
    else
      if is_struct(List.first(values), ElementHandle) do
        elements =
          Enum.into(values, [], fn value ->
            select_option_value(value)
          end)

        %{elements: elements}
      else
        options =
          Enum.into(values, [], fn value ->
            select_option_value(value)
          end)

        %{options: options}
      end
    end
  end

  defp select_option_value(value) when is_binary(value) do
    %{value: value}
  end

  defp select_option_value(%{index: _} = value) when is_map(value) do
    value
  end

  defp select_option_value(%{label: _} = value) when is_map(value) do
    value
  end

  defp select_option_value(%{value: _} = value) when is_map(value) do
    value
  end

  defp select_option_value(%ElementHandle{guid: guid}) do
    %{guid: guid}
  end

  defp serialize(arg) do
    Helpers.Serialization.serialize(arg)
  end
end
