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

  @property :load_states
  @property :url

  @type expression :: binary()
  @type options :: map()
  @type serializable :: any()
  @type load_state :: atom() | binary()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, _initializer) do
    Channel.bind(owner, :loadstate, fn %{params: params} = event ->
      target = event.target

      case params do
        %{add: state} ->
          {:patch, %{target | load_states: target.load_states ++ [state]}}

        %{remove: state} ->
          {:patch, %{target | load_states: target.load_states -- [state]}}
      end
    end)

    Channel.bind(owner, :navigated, fn event ->
      {:patch, %{event.target | url: event.params.url}}
    end)

    {:ok, owner}
  end

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec add_script_tag(Frame.t(), options()) :: {:ok, ElementHandle.t()}
  # def add_script_tag(owner, options \\ %{})

  # @spec add_style_tag(Frame.t(), options()) :: {:ok, ElementHandle.t()}
  # def add_style_tag(owner, options \\ %{})

  # @spec check(Frame.t(), binary(), options()) :: :ok
  # def check(owner, selector, options \\ %{})

  # @spec child_frames(Frame.t()) :: {:ok, [Frame.t()]}
  # def child_frames(owner)

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
  @spec click(struct(), binary(), options()) :: :ok
  def click(owner, selector, options \\ %{})

  def click(%Page{} = owner, selector, options) do
    from(owner) |> click(selector, options)
  end

  def click(%Frame{} = owner, selector, options) do
    params =
      Map.merge(
        %{
          selector: selector,
          timeout: 30_000,
          wait_until: "load"
        },
        options
      )

    {:ok, _} = Channel.post(owner, :click, params)
    :ok
  end

  def click({:ok, owner}, selector, options) do
    click(owner, selector, options)
  end

  # ---

  # @spec content(Frame.t()) :: {:ok, binary()}
  # def content(owner)

  # @spec dblclick(Frame.t(), binary(), options()) :: :ok
  # def dblclick(owner, selector, options \\ %{})

  # @spec dispatch_event(Frame.t(), binary(), binary(), evaluation_argument(), options()) :: :ok
  # def dispatch_event(owner, selector, type, arg, options \\ %{})

  # @spec drag_and_drop(Frame.t(), binary(), binary(), options()) :: :ok
  # def drag_and_drop(owner, source, target, options \\ %{})

  # @spec eval_on_selector(Frame.t(), binary(), expression(), any(), options()) :: :ok
  # def eval_on_selector(owner, selector, expression, arg \\ nil, options \\ %{})

  # @spec eval_on_selector_all(Frame.t(), binary(), expression(), any(), options()) :: :ok
  # def eval_on_selector_all(owner, selector, expression, arg \\ nil, options \\ %{})

  # ---

  @doc """
  Returns the return value of `expression`.

  !!!
  """
  @spec eval_on_selector(Frame.t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(owner, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Frame{} = owner, selector, expression, arg, _options) do
    Channel.post(owner, :eval_on_selector, %{
      selector: selector,
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
  end

  @doc """
  Returns the return value of `expression`.

  !!!
  """
  @spec evaluate(Frame.t() | Page.t(), expression(), any()) :: {:ok, serializable()}
  def evaluate(owner, expression, arg \\ nil)

  def evaluate(%Frame{} = owner, expression, arg) do
    Channel.post(owner, :evaluate_expression, %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
    |> Helpers.Serialization.deserialize()
  end

  def evaluate(%Page{} = owner, expression, arg) do
    from(owner) |> evaluate(expression, arg)
  end

  def evaluate({:ok, owner}, expression, arg) do
    evaluate(owner, expression, arg)
  end

  @doc """
  Returns the return value of `expression` as a `Playwright.JSHandle`.

  !!!
  """
  @spec evaluate_handle(Frame.t() | Page.t(), expression(), any()) :: {:ok, serializable()}
  def evaluate_handle(owner, expression, arg \\ nil)

  def evaluate_handle(%Frame{} = owner, expression, arg) do
    Channel.post(owner, :evaluate_expression_handle, %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
  end

  def evaluate_handle(%Page{} = owner, expression, arg) do
    from(owner) |> evaluate_handle(expression, arg)
  end

  def evaluate_handle({:ok, owner}, expression, arg) do
    evaluate_handle(owner, expression, arg)
  end

  # ---

  # @spec expect_navigation(Frame.t(), function(), options()) :: {:ok, Playwright.Response.t() | nil}
  # def expect_navigation(owner, trigger, options \\ %{})

  # ---

  @doc """
  Waits for an element matching the `selector`, waits for
  "actionability (guide)" checks, focuses the element, fills it and triggers an
  input event after filling.

  Note that you can pass an empty string to clear the input field.

  If the target element is not an `<input>`, `<textarea>` or `contenteditable`
  element, this function raises an error. However, if the element is inside the
  `<label>` element that has an associated control, the control will be filled
  instead.

  To send fine-grained keyboard events, use `Playwright.Frame.type/4`.
  """
  @spec fill(Frame.t(), binary(), binary()) :: :ok
  def fill(%Frame{} = owner, selector, value) do
    {:ok, _} = Channel.post(owner, :fill, %{selector: selector, value: value})
    :ok
  end

  @spec fill(Page.t(), binary(), binary()) :: {:ok, Page.t()}
  def fill(%Page{} = owner, selector, value) do
    from(owner) |> fill(selector, value)
  end

  # ---

  # @spec focus(Frame.t(), binary(), options()) :: :ok
  # def focus(owner, trigger, options \\ %{})

  # @spec frame_element(Frame.t()) :: {:ok, ElementHandle.t()}
  # def frame_element(owner)

  # @spec frame_locator(Frame.t(), binary()) :: {:ok, Locator.t()}
  # def frame_locator(owner, selector)

  # ---

  @doc """
  Returns element attribute value.

  !!!
  """
  @spec get_attribute(Frame.t() | Page.t(), binary(), binary(), map()) :: {:ok, binary() | nil}
  def get_attribute(owner, selector, name, options \\ %{})

  def get_attribute(%Frame{} = owner, selector, name, _options) do
    owner
    |> query_selector!(selector)
    |> ElementHandle.get_attribute(name)
  end

  def get_attribute(%Page{} = owner, selector, name, options) do
    from(owner) |> get_attribute(selector, name, options)
  end

  @doc """
  !!!
  """
  @spec goto(Page.t(), binary(), map()) :: {:ok, Response.t()} | {:error, term()}
  def goto(owner, url, params \\ %{})

  def goto(%Page{} = owner, url, _params) do
    Channel.post(from(owner), :goto, %{url: url})
  end

  def goto({:ok, owner}, url, params) do
    goto(owner, url, params)
  end

  # ---

  # @spec hover(Frame.t(), binary(), options()) :: :ok
  # def hover(owner, selector, options \\ %{})

  # @spec inner_html(Frame.t(), binary(), options()) :: {:ok, binary()}
  # def inner_html(owner, selector, options \\ %{})

  # @spec inner_text(Frame.t(), binary(), options()) :: {:ok, binary()}
  # def inner_text(owner, selector, options \\ %{})

  # @spec input_value(Frame.t(), binary(), options()) :: {:ok, binary()}
  # def input_value(owner, selector, options \\ %{})

  # @spec is_checked(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_checked(owner, selector, options \\ %{})

  # @spec is_detached(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_detached(owner, selector, options \\ %{})

  # @spec is_disabled(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_disabled(owner, selector, options \\ %{})

  # @spec is_editable(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_editable(owner, selector, options \\ %{})

  # @spec is_enabled(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_enabled(owner, selector, options \\ %{})

  # @spec is_hidden(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_hidden(owner, selector, options \\ %{})

  # @spec is_visible(Frame.t(), binary(), options()) :: {:ok, boolean()}
  # def is_visible(owner, selector, options \\ %{})

  # @spec locator(Frame.t(), binary()) :: Playwright.Locator.t()
  # def locator(owner, selector)

  # @spec name(Frame.t()) :: binary()
  # def name(owner)

  # @spec page(Frame.t()) :: Page.t()
  # def page(owner)

  # @spec parent_page(Frame.t()) :: Frame.t()
  # def parent_page(owner)

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

  def press(%Page{} = owner, selector, key, options) do
    from(owner) |> press(selector, key, options)
  end

  def press(%Frame{} = owner, selector, key, options) do
    {:ok, _} = Channel.post(owner, :press, Map.merge(%{selector: selector, key: key}, options))
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
  @spec query_selector(Frame.t() | Page.t(), binary(), map()) :: {:ok, ElementHandle.t() | nil}
  def query_selector(owner, selector, options \\ %{})

  def query_selector(%Page{} = owner, selector, options) do
    from(owner) |> query_selector(selector, options)
  end

  def query_selector(%Frame{} = owner, selector, options) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(owner, :query_selector, params)
  end

  def query_selector({:ok, owner}, selector, options) do
    query_selector(owner, selector, options)
  end

  defdelegate q(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector

  # NOTE: this should either delegate to `query_selector` w/ `strict: true`, or
  # be removed.
  @doc false
  @spec query_selector!(struct(), binary(), map()) :: struct()
  def query_selector!(owner, selector, options \\ %{})

  def query_selector!(%Page{} = owner, selector, options) do
    from(owner) |> query_selector!(selector, options)
  end

  def query_selector!(%Frame{} = owner, selector, options) do
    case query_selector(owner, selector, options) do
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
  @spec query_selector_all(Frame.t() | Page.t(), binary(), map()) :: {atom(), [ElementHandle.t()]}
  def query_selector_all(owner, selector, options \\ %{})

  def query_selector_all(%Page{} = owner, selector, options) do
    from(owner) |> query_selector_all(selector, options)
  end

  def query_selector_all(%Frame{} = owner, selector, options) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(owner, :query_selector_all, params)
  end

  def query_selector_all({:ok, owner}, selector, options) do
    query_selector_all(owner, selector, options)
  end

  defdelegate qq(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector_all

  # ---

  # @spec select_option(Frame.t(), binary(), any(), options()) :: {:ok, [binary()]}
  # def select_option(owner, selector, values, options \\ %{})

  # @spec set_checked(Frame.t(), boolean(), options()) :: :ok
  # def set_checked(owner, checked, options \\ %{})

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
  @spec set_content(Frame.t() | Page.t(), binary(), options()) :: :ok
  def set_content(owner, html, options \\ %{})

  def set_content(%Frame{} = owner, html, options) do
    params = Map.merge(%{html: html, timeout: 30_000, wait_until: "load"}, options)
    {:ok, _response} = Channel.post(owner, :set_content, params)
    :ok
  end

  def set_content(%Page{} = owner, html, options) do
    from(owner) |> set_content(html, options)
  end

  def set_content({:ok, owner}, html, options) do
    set_content(owner, html, options)
  end

  # ---

  # @spec set_input_files(Frame.t(), binary(), any(), options()) :: :ok
  # def set_input_files(owner, selector, files, options \\ %{})

  # @spec tap(Frame.t(), binary(), options()) :: :ok
  # def tap(owner, selector, options \\ %{})

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

  def text_content(%Frame{} = owner, selector, options) do
    Channel.post(owner, :text_content, Map.merge(%{selector: selector}, options))
  end

  def text_content(%Page{} = owner, selector, options) do
    from(owner) |> text_content(selector, options)
  end

  @doc """
  Returns the page title.

  ## Returns

    - `{:ok, binary()}`
  """
  @spec title(Frame.t() | Page.t()) :: {:ok, binary()}
  def title(owner)

  def title(%Frame{} = owner) do
    Channel.post(owner, :title)
  end

  def title(%Page{} = owner) do
    from(owner) |> title()
  end

  # ---

  # @spec type(Frame.t(), binary(), binary(), options()) :: :ok
  # def type(owner, selector, text, options \\ %{})

  # @spec uncheck(Frame.t(), binary(), options()) :: :ok
  # def uncheck(owner, selector, options \\ %{})

  # @spec wait_for_function(Frame.t(), expression(), any(), options()) :: {:ok, JSHandle.t()}
  # def wait_for_function(owner, expression, arg \\ nil, options \\ %{})

  # ---

  @doc """
  Waits for the required load state to be reached.

  This returns when the frame reaches a required load state, "load" by default.
  The navigation must have been committed when this method is called. If
  the current document has already reached the required state, resolves
  immediately.
  """
  @spec wait_for_load_state(Frame.t(), binary(), options()) :: {:ok, Frame.t()}
  def wait_for_load_state(owner, state \\ "load", options \\ %{})

  def wait_for_load_state(%Frame{} = owner, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    if Enum.member?(owner.load_states, state) do
      {:ok, owner}
    else
      {:ok, _} = Channel.wait_for(owner, :loadstate)
      {:ok, owner}
    end
  end

  def wait_for_load_state(%Frame{} = owner, state, options) when is_binary(state) do
    wait_for_load_state(owner, state, options)
  end

  def wait_for_load_state(%Frame{} = owner, options, _) when is_map(options) do
    wait_for_load_state(owner, "load", options)
  end

  # ---

  # @spec wait_for_navigation(Frame.t(), options()) :: :ok
  # def wait_for_navigation(owner, options \\ %{})

  # ---

  @doc """
  Returns when element specified by selector satisfies state option.

  Returns `nil` if waiting for a hidden or detached element.
  """
  @spec wait_for_selector(Frame.t() | Page.t(), binary(), map()) :: {:ok, ElementHandle.t() | nil}
  def wait_for_selector(owner, selector, options \\ %{})

  def wait_for_selector(%Frame{} = owner, selector, options) do
    Channel.post(owner, :wait_for_selector, Map.merge(%{selector: selector}, options))
  end

  def wait_for_selector(%Page{} = owner, selector, options) do
    from(owner) |> wait_for_selector(selector, options)
  end

  # ---

  # @spec wait_for_timeout(Frame.t(), number()) :: :ok
  # def wait_for_timeout(owner, timeout)

  # @spec wait_for_url(Frame.t(), binary(), options()) :: :ok
  # def wait_for_url(owner, url, options \\ %{})

  # ---

  # private
  # ---------------------------------------------------------------------------

  defp from(%Page{} = owner) do
    {:ok, frame} = Channel.find(owner, owner.main_frame)
    frame
  end
end
