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
  use Playwright.ChannelOwner
  alias Playwright.{ChannelOwner, ElementHandle, Frame, Page, Response}
  alias Playwright.Runner.{EventInfo, Helpers}

  # temp/hack to get navigation_test passing. a better fix is to replace the
  # current delegate+property approach.
  def url(%Page{} = page) do
    from(page) |> url()
  end

  @property :load_states
  @property :url

  @type expression :: binary()
  @type options :: map()
  @type serializable :: any()
  @type load_state :: atom() | binary()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(frame, _initializer) do
    Channel.bind(frame, :loadstate, fn %{params: params} = event ->
      target = event.target

      case params do
        %{add: state} ->
          {:patch, %{target | load_states: target.load_states ++ [state]}}

        %{remove: state} ->
          {:patch, %{target | load_states: target.load_states -- [state]}}
      end
    end)

    Channel.bind(frame, :navigated, fn event ->
      {:patch, %{event.target | url: event.params.url}}
    end)

    {:ok, frame}
  end

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec add_script_tag(Frame.t(), options()) :: {:ok, ElementHandle.t()}
  # def add_script_tag(frame, options \\ %{})

  # @spec add_style_tag(Frame.t(), options()) :: {:ok, ElementHandle.t()}
  # def add_style_tag(frame, options \\ %{})

  # @spec check(Frame.t(), binary(), options()) :: :ok
  # def check(frame, selector, options \\ %{})

  # @spec child_frames(Frame.t()) :: {:ok, [Frame.t()]}
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
  @spec click(t() | Page.t() | {:ok, t() | Page.t()}, binary(), options()) :: :ok
  def click(owner, selector, options \\ %{})

  def click(%Page{} = page, selector, options) do
    from(page) |> click(selector, options)
  end

  def click(%Frame{} = frame, selector, options) do
    params =
      Map.merge(
        %{
          selector: selector,
          timeout: 30_000,
          wait_until: "load"
        },
        options
      )

    {:ok, _} = Channel.post(frame, :click, params)
    :ok
  end

  def click({:ok, owner}, selector, options) do
    click(owner, selector, options)
  end

  # ---

  # @spec content(Frame.t()) :: {:ok, binary()}
  # def content(frame)

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

    - `:ok`

  ## Arguments

  | key / name       | type   |                                   | description |
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
  @spec dblclick(Frame.t(), binary(), options()) :: :ok
  def dblclick(frame, selector, options \\ %{}) do
    params =
      Map.merge(
        %{
          selector: selector
        },
        options
      )

    {:ok, _} = Channel.post(frame, :dblclick, params)
    :ok
  end

  # ---

  # @spec dispatch_event(Frame.t(), binary(), binary(), evaluation_argument(), options()) :: :ok
  # def dispatch_event(frame, selector, type, arg, options \\ %{})

  # @spec drag_and_drop(Frame.t(), binary(), binary(), options()) :: :ok
  # def drag_and_drop(frame, source, target, options \\ %{})

  # @spec eval_on_selector(Frame.t(), binary(), expression(), any(), options()) :: :ok
  # def eval_on_selector(frame, selector, expression, arg \\ nil, options \\ %{})

  # @spec eval_on_selector_all(Frame.t(), binary(), expression(), any(), options()) :: :ok
  # def eval_on_selector_all(frame, selector, expression, arg \\ nil, options \\ %{})

  # ---

  @doc """
  Returns the return value of `expression`.

  !!!
  """
  @spec eval_on_selector(Frame.t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(frame, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Frame{} = frame, selector, expression, arg, _options) do
    Channel.post(frame, :eval_on_selector, %{
      selector: selector,
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
  end

  def eval_on_selector_all(%Frame{} = frame, selector, expression, arg \\ nil) do
    Channel.post(frame, :eval_on_selector_all, %{
      selector: selector,
      expression: expression,
      arg: Helpers.Serialization.serialize(arg)
    })
    |> Helpers.Serialization.deserialize()
  end

  @doc """
  Returns the return value of `expression`.

  !!!
  """
  @spec evaluate(t() | Page.t() | {:ok, t() | Page.t()}, expression(), any()) :: {:ok, serializable()}
  def evaluate(owner, expression, arg \\ nil)

  def evaluate(%Frame{} = frame, expression, arg) do
    Channel.post(frame, :evaluate_expression, %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
    |> Helpers.Serialization.deserialize()
  end

  def evaluate(%Page{} = page, expression, arg) do
    from(page) |> evaluate(expression, arg)
  end

  def evaluate({:ok, owner}, expression, arg) do
    evaluate(owner, expression, arg)
  end

  @doc """
  Returns the return value of `expression` as a `Playwright.JSHandle`.

  !!!
  """
  @spec evaluate_handle(t() | Page.t() | {:ok, t() | Page.t()}, expression(), any()) :: {:ok, serializable()}
  def evaluate_handle(owner, expression, arg \\ nil)

  def evaluate_handle(%Frame{} = frame, expression, arg) do
    Channel.post(frame, :evaluate_expression_handle, %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
  end

  def evaluate_handle(%Page{} = page, expression, arg) do
    from(page) |> evaluate_handle(expression, arg)
  end

  def evaluate_handle({:ok, owner}, expression, arg) do
    evaluate_handle(owner, expression, arg)
  end

  # ---

  # @spec expect_navigation(Frame.t(), function(), options()) :: {:ok, Playwright.Response.t() | nil}
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

    - `:ok`

  ## Arguments

  | key / name       | type   |                                   | description |
  | ---------------- | ------ | --------------------------------- | ----------- |
  | `selector`       | param  | `binary()`                        | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `value`          | param  | `binary()`                        | Value to fill for the `<input>`, `<textarea>` or `[contenteditable]` element |
  | `:force`         | option | `boolean()`                       | Whether to bypass the actionability checks. `(default: false)` |
  | `:no_wait_after` | option | `boolean()`                       | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:strict`        | option | `boolean()`                       | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout`       | option | `number()`                        | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec fill(t() | Page.t(), binary(), binary(), options()) :: :ok
  def fill(frame, selector, value, options \\ %{})

  def fill(%Frame{} = frame, selector, value, options) do
    params = Map.merge(options, %{selector: selector, value: value})
    {:ok, _} = Channel.post(frame, :fill, params)
    :ok
  end

  def fill(%Page{} = page, selector, value, options) do
    from(page) |> fill(selector, value, options)
  end

  # ---

  @doc """
  Fetches an element with `param: selector` and focuses it.

  If no element matches the selector, waits until a matching element appears in the DOM.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:strict`  | option | `boolean()` | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout` | option | `number()`  | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec focus(t(), binary(), options()) :: :ok
  def focus(%Frame{} = frame, selector, options \\ %{}) do
    params = Map.merge(options, %{selector: selector})
    {:ok, _} = Channel.post(frame, :focus, params)
    :ok
  end

  # @spec frame_element(Frame.t()) :: {:ok, ElementHandle.t()}
  # def frame_element(frame)

  # @spec frame_locator(Frame.t(), binary()) :: {:ok, Locator.t()}
  # def frame_locator(frame, selector)

  # ---

  @doc """
  Returns element attribute value.
  !!!
  """
  @spec get_attribute(t() | Page.t() | {:ok, t() | Page.t()}, binary(), binary(), map()) :: {:ok, binary() | nil}
  def get_attribute(owner, selector, name, options \\ %{})

  def get_attribute(%Frame{} = frame, selector, name, options) do
    params =
      Map.merge(options, %{
        selector: selector,
        name: name
      })

    Channel.post(frame, :get_attribute, params)
  end

  def get_attribute(%Page{} = page, selector, name, options) do
    from(page) |> get_attribute(selector, name, options)
  end

  @doc """
  !!!
  """
  @spec goto(t() | Page.t() | {:ok, t() | Page.t()}, binary(), map()) :: {:ok, Response.t()} | {:error, term()}
  def goto(owner, url, params \\ %{})

  def goto(%Page{} = page, url, _params) do
    Channel.post(from(page), :goto, %{url: url})
  end

  def goto({:ok, owner}, url, params) do
    goto(owner, url, params)
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

  | key / name       | type   |                                   | description |
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
  @spec hover(Frame.t(), binary(), options()) :: :ok
  def hover(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    {:ok, _} = Channel.post(frame, :hover, params)
    :ok
  end

  @spec inner_html(Frame.t(), binary(), options()) :: {:ok, binary()}
  def inner_html(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, "innerHTML", params)
  end

  @spec inner_text(Frame.t(), binary(), options()) :: {:ok, binary()}
  def inner_text(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :inner_text, params)
  end

  @spec input_value(Frame.t(), binary(), options()) :: {:ok, binary()}
  def input_value(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :input_value, params)
  end

  @spec is_checked(Frame.t(), binary(), options()) :: {:ok, boolean()}
  def is_checked(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :is_checked, params)
  end

  # @spec is_detached(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_detached(frame, selector, options \\ %{})

  @spec is_disabled(Frame.t(), binary(), options()) :: {:ok, boolean()}
  def is_disabled(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :is_disabled, params)
  end

  @spec is_editable(Frame.t(), binary(), options()) :: {:ok, boolean()}
  def is_editable(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :is_editable, params)
  end

  @spec is_enabled(Frame.t(), binary(), options()) :: {:ok, boolean()}
  def is_enabled(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :is_enabled, params)
  end

  @spec is_hidden(Frame.t(), binary(), options()) :: {:ok, boolean()}
  def is_hidden(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :is_hidden, params)
  end

  @spec is_visible(Frame.t(), binary(), options()) :: {:ok, boolean()}
  def is_visible(frame, selector, options \\ %{}) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :is_visible, params)
  end

  # ---

  # @spec locator(Frame.t(), binary()) :: Playwright.Locator.t()
  # def locator(frame, selector)

  # @spec name(Frame.t()) :: binary()
  # def name(frame)

  # @spec page(Frame.t()) :: Page.t()
  # def page(frame)

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

    - :ok

  ## Arguments

  | key / name       | type   |              | description |
  | ---------------- | ------ | ------------ | ----------- |
  | `selector`       | param  | `binary()`   | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `key`            | param  | `binary()`   | Name of the key to press or a character to generate, such as `ArrowLeft` or `a`. |
  | `:delay`         | option | `number() `  | Time to wait between keydown and keyup in milliseconds. `(default: 0)` |
  | `:no_wait_after` | option | `boolean()`  | Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. `(default: false)` |
  | `:strict`        | option | `boolean()`  | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout`       | option | `number()`   | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec press(Frame.t() | Page.t(), binary(), binary(), options()) :: :ok
  def press(owner, selector, key, options \\ %{})

  def press(%Page{} = page, selector, key, options) do
    from(page) |> press(selector, key, options)
  end

  def press(%Frame{} = frame, selector, key, options) do
    {:ok, _} = Channel.post(frame, :press, Map.merge(%{selector: selector, key: key}, options))
    :ok
  end

  @doc """
  Returns the `Playwright.ElementHandle` pointing to the frame element.

  The function finds an element matching the specified selector within the
  frame. See "working with selectors (guide)" for more details. If no elements
  match the selector, returns `nil`.

  ## Returns
    - `{:ok, Playwright.ElementHandle.t() | nil}`

  ## Arguments

  | key / name | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to query for. See "working with selectors (guide)" for more details. |
  | `strict`   | option | `boolean()` | When true, the call requires `selector` to resolve to a single element. If the given `selector` resolves to more then one element, the call raises an error. |
  """
  @spec query_selector(t() | Page.t() | {:ok, t() | Page.t()}, binary(), map()) :: {:ok, ElementHandle.t() | nil}
  def query_selector(owner, selector, options \\ %{})

  def query_selector(%Page{} = page, selector, options) do
    from(page) |> query_selector(selector, options)
  end

  def query_selector(%Frame{} = frame, selector, options) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :query_selector, params)
  end

  def query_selector({:ok, owner}, selector, options) do
    query_selector(owner, selector, options)
  end

  defdelegate q(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector

  # NOTE: this should either delegate to `query_selector` w/ `strict: true`, or
  # be removed.
  @doc false
  @spec query_selector!(t() | Page.t() | {:ok, t() | Page.t()}, binary(), map()) :: struct()
  def query_selector!(owner, selector, options \\ %{})

  def query_selector!(%Page{} = page, selector, options) do
    from(page) |> query_selector!(selector, options)
  end

  def query_selector!(%Frame{} = frame, selector, options) do
    case query_selector(frame, selector, options) do
      {:ok, nil} -> raise "No element found for selector: #{selector}"
      {:ok, handle} -> handle
    end
  end

  def query_selector!({:ok, owner}, selector, options) do
    query_selector!(owner, selector, options)
  end

  defdelegate q!(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector!

  @doc """
  Returns the list of `Playwright.ElementHandle` pointing to the frame elements.

  The method finds all elements matching the specified selector within the
  frame. See "working with selectors (guide)" for more details.

  If no elements match the selector, returns an empty `List`.

  ## Returns

    - `{:ok, [Playwright.ElementHandle.t()]}`

  ## Arguments

  | key / name | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to query for. See "working with selectors (guide)" for more details. |
  """
  @spec query_selector_all(t() | Page.t() | {:ok, t() | Page.t()}, binary(), map()) :: {atom(), [ElementHandle.t()]}
  def query_selector_all(owner, selector, options \\ %{})

  def query_selector_all(%Page{} = page, selector, options) do
    from(page) |> query_selector_all(selector, options)
  end

  def query_selector_all(%Frame{} = frame, selector, options) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(frame, :query_selector_all, params)
  end

  def query_selector_all({:ok, owner}, selector, options) do
    query_selector_all(owner, selector, options)
  end

  defdelegate qq(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector_all

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

    - `{:ok, [binary()]}`

  ## Arguments

  | key / name       | type   |                 | description |
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
  @spec select_option(Frame.t(), binary(), any(), options()) :: {:ok, [binary()]}
  def select_option(%Frame{} = frame, selector, values, options \\ %{}) do
    params = Map.merge(options, Map.merge(select_option_values(values), %{selector: selector}))
    Channel.post(frame, :select_option, params)
  end

  # ---

  # @spec set_checked(Frame.t(), boolean(), options()) :: :ok
  # def set_checked(frame, checked, options \\ %{})

  # ---

  @doc """
  ## Returns

    - `:ok`

  ## Arguments

  | key / name | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `html`     | param  | `binary()`  | HTML markup to assign to the page. |
  | `timeout`  | option | `number()`  | Maximum operation time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_navigation_timeout/2`, `Playwright.BrowserContext.set_default_timeout/2`, `Playwright.Page.set_default_navigation_timeout/2` or `Playwright.Page.set_default_timeout/` functions. `(default: 30 seconds)` |
  """
  @spec set_content(t() | Page.t() | {:ok, t() | Page.t()}, binary(), options()) :: :ok
  def set_content(owner, html, options \\ %{})

  def set_content(%Frame{} = frame, html, options) do
    params = Map.merge(%{html: html, timeout: 30_000, wait_until: "load"}, options)
    {:ok, _response} = Channel.post(frame, :set_content, params)
    :ok
  end

  def set_content(%Page{} = page, html, options) do
    from(page) |> set_content(html, options)
  end

  def set_content({:ok, owner}, html, options) do
    set_content(owner, html, options)
  end

  # ---

  # @spec set_input_files(Frame.t(), binary(), any(), options()) :: :ok
  # def set_input_files(frame, selector, files, options \\ %{})

  # @spec tap(Frame.t(), binary(), options()) :: :ok
  # def tap(frame, selector, options \\ %{})

  # ---

  @doc """
  Returns `Playwright.ElementHandle.text_content/1`

  ## Returns

    - `{:ok, binary() | nil}`

  ## Arguments

  | key / name | type   |             | description |
  | ---------- | ------ | ----------- | ----------- |
  | `selector` | param  | `binary()`  | A selector to search for an element. If there are multiple elements satisfying the selector, the first will be used. See "working with selectors (guide)" for more details. |
  | `:strict`  | option | `boolean()` | When true, the call requires selector to resolve to a single element. If given selector resolves to more then one element, the call throws an exception. |
  | `:timeout` | option | `number()`  | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed by using the `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2` functions. `(default: 30 seconds)` |
  """
  @spec text_content(Frame.t() | Page.t(), binary(), map()) :: {:ok, binary() | nil}
  def text_content(owner, selector, options \\ %{})

  def text_content(%Frame{} = frame, selector, options) do
    Channel.post(frame, :text_content, Map.merge(%{selector: selector}, options))
  end

  def text_content(%Page{} = page, selector, options) do
    from(page) |> text_content(selector, options)
  end

  @doc """
  Returns the page title.

  ## Returns

    - `{:ok, binary()}`
  """
  @spec title(Frame.t() | Page.t()) :: {:ok, binary()}
  def title(owner)

  def title(%Frame{} = frame) do
    Channel.post(frame, :title)
  end

  def title(%Page{} = page) do
    from(page) |> title()
  end

  # ---

  # @spec type(Frame.t(), binary(), binary(), options()) :: :ok
  # def type(frame, selector, text, options \\ %{})

  # @spec uncheck(Frame.t(), binary(), options()) :: :ok
  # def uncheck(frame, selector, options \\ %{})

  # @spec wait_for_function(Frame.t(), expression(), any(), options()) :: {:ok, JSHandle.t()}
  # def wait_for_function(frame, expression, arg \\ nil, options \\ %{})

  # ---

  @doc """
  Waits for the required load state to be reached.

  This returns when the frame reaches a required load state, "load" by default.
  The navigation must have been committed when this method is called. If
  the current document has already reached the required state, resolves
  immediately.
  """
  @spec wait_for_load_state(Frame.t(), binary(), options()) :: {:ok, Frame.t()}
  def wait_for_load_state(frame, state \\ "load", options \\ %{})

  def wait_for_load_state(%Frame{} = frame, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    if Enum.member?(frame.load_states, state) do
      {:ok, frame}
    else
      {:ok, _} = Channel.wait_for(frame, :loadstate)
      {:ok, frame}
    end
  end

  def wait_for_load_state(%Frame{} = frame, state, options) when is_binary(state) do
    wait_for_load_state(frame, state, options)
  end

  def wait_for_load_state(%Frame{} = frame, options, _) when is_map(options) do
    wait_for_load_state(frame, "load", options)
  end

  # ---

  # @spec wait_for_navigation(Frame.t(), options()) :: :ok
  # def wait_for_navigation(frame, options \\ %{})

  # ---

  @doc """
  Returns when element specified by selector satisfies state option.

  Returns `nil` if waiting for a hidden or detached element.
  """
  @spec wait_for_selector(Frame.t() | Page.t(), binary(), map()) :: {:ok, ElementHandle.t() | nil}
  def wait_for_selector(owner, selector, options \\ %{})

  def wait_for_selector(%Frame{} = frame, selector, options) do
    Channel.post(frame, :wait_for_selector, Map.merge(%{selector: selector}, options))
  end

  def wait_for_selector(%Page{} = page, selector, options) do
    from(page) |> wait_for_selector(selector, options)
  end

  # ---

  # @spec wait_for_timeout(Frame.t(), number()) :: :ok
  # def wait_for_timeout(frame, timeout)

  # @spec wait_for_url(Frame.t(), binary(), options()) :: :ok
  # def wait_for_url(frame, url, options \\ %{})

  # ---

  # private
  # ---------------------------------------------------------------------------

  defp from(%Page{} = page) do
    {:ok, frame} = Channel.find(page, page.main_frame)
    frame
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
        # "elements":[{"guid":"handle@861d62cf4e61c383ddd049a675c895eb"}]
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
end
