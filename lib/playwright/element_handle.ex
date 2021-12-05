defmodule Playwright.ElementHandle do
  @moduledoc """
  `ElementHandle` represents an in-page DOM element.

  `ElementHandles` can be created with the `Playwright.Page.query_selector/3`
  function, and similar.

  > ⚠️ DISCOURAGED
  >
  > The use of `Playwright.ElementHandle` is discouraged; use
  > `Playwright.Locator` instances and web-first assertions instead.

  ## Example

      {:ok, handle} = Page.q(page, "a")
      :ok = ElementHandle.click(handle)

  `ElementHandle` prevents DOM elements from garbage collection unless the
  handle is disposed with `Playwright.JSHandle.dispose/1`. `ElementHandles`
  are auto-disposed when their origin frame is navigated.

  An `ElementHandle` instance can be used as an argument in
  `Playwright.Page.eval_on_selector/5` and `Playwright.Page.evaluate/3`.

  ## NOTE

  > In most cases, you would want to use `Playwright.Locator` instead. You
  > should only use `ElementHandle` if you want to retain a handle to a
  > particular DOM node that you intend to pass into
  > `Playwright.Page.evaluate/3` as an argument.

  The difference between `Playwright.Locator` and `ElementHandle` is that
  `ElementHandle` points to a particular element, while `Playwright.Locator`
  captures the logic of how to retrieve an element.

  In the example below, `handle` points to a particular DOM element on the
  page. If that element changes text or is used by JavaScript to render an
  entirely different component, `handle` still points to that very DOM element.
  This can lead to unexpected behaviors.

      {:ok, handle} = Page.q("text=Submit")
      ElementHandle.hover(handle)
      ElementHandle.click(handle)

  With the `Playwright.Locator`, every time the `locator` is used, an
  up-to-date DOM element is located in the page using the selector. So, in the
  snippet below, the underlying DOM element is going to be located twice.

      {:ok, locator} = Page.locator("text=Submit")
      Locator.hover(locator)
      Locator.click(locator)

  """

  use Playwright.ChannelOwner
  alias Playwright.{ChannelOwner, ElementHandle, Frame, JSHandle}
  alias Playwright.Runner.Channel

  @property :preview

  @typedoc "A map/struct providing call options"
  @type options :: map()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%ElementHandle{} = handle, _initializer) do
    Channel.bind(handle, :preview_updated, fn %{params: params} = event ->
      {:patch, %{event.target | preview: params.preview}}
    end)
  end

  # delegates
  # ---------------------------------------------------------------------------

  defdelegate evaluate(handle, expression, arg \\ nil),
    to: JSHandle

  defdelegate evaluate_handle(handle, expression, arg \\ nil),
    to: JSHandle

  defdelegate string(handle),
    to: JSHandle

  # API
  # ---------------------------------------------------------------------------

  @spec bounding_box(ElementHandle.t()) :: {:ok, map() | nil}
  def bounding_box(handle) do
    Channel.post(handle, :bounding_box)
  end

  # ---

  # @spec check(ElementHandle.t(), options()) :: :ok
  # def check(handle, options \\ %{})

  # @spec click(ElementHandle.t(), options()) :: :ok
  # def click(handle, options \\ %{})

  # ---

  @doc """
  Clicks on the element, performing the following steps:

    1. Wait for "actionability (guide)" checks on the element, unless `force: true`
       option is set.
    2. Scroll the element into view, if needed.
    3. Use `Playwright.Page.Mouse` to click the center of the elemnt, or the
       specified option: `position`.
    4. Wait for initiated navigations to either succeed or fail, unless
      `no_wait_after: true` option is set.

  If the element is detached from the DOM at any moment during the action,
  this function raises.

  When all steps combined have not finished during the specified `:timeout`,
  this function raises a `TimeoutError`. Passing zero (`0`) for timeout
  disables this.
  """
  @spec click(t() | {:ok, t()}, options()) :: :ok
  def click(%ElementHandle{} = handle, options \\ %{}) do
    Channel.post!(handle, :click, options)
  end

  @doc """
  Returns the `Playwright.Frame` for element handles referencing iframe nodes,
  or `nil` otherwise.
  """
  @spec content_frame(t()) :: Frame.t() | nil
  def content_frame(%ElementHandle{} = handle) do
    Channel.post!(handle, :content_frame)
  end

  # ---

  # @spec dblclick(ElementHandle.t(), options()) :: :ok
  # def dblclick(handle, options \\ %{})

  # @spec dispatch_event(ElementHandle.t(), event(), evaluation_argument()) :: :ok
  # def dispatch_event(handle, type, arg \\ nil)

  # @spec fill(ElementHandle.t(), binary(), options()) :: :ok
  # def fill(handle, value, options \\ %{})

  # @spec focus(ElementHandle.t()) :: :ok
  # def focus(handle)

  # ---

  @doc """
  Returns the value of an element's attribute.
  """
  @spec get_attribute(t(), binary()) :: {:ok, binary() | nil}
  def get_attribute(handle, name)

  def get_attribute(%ElementHandle{} = handle, name) do
    Channel.post(handle, :get_attribute, %{name: name})
  end

  # ---

  # @spec hover(ElementHandle.t(), options()) :: :ok
  # def hover(handle, options \\ %{})

  # @spec inner_html(ElementHandle.t()) :: {:ok, binary() | nil}
  # def inner_html(handle)

  # @spec inner_text(ElementHandle.t()) :: {:ok, binary() | nil}
  # def inner_text(handle)

  # @spec input_value(ElementHandle.t(), options()) :: {:ok, binary()}
  # def input_value(handle, options)

  # @spec is_checked(ElementHandle.t()) :: {:ok, boolean()}
  # def is_checked(handle)

  # @spec is_disabled(ElementHandle.t()) :: {:ok, boolean()}
  # def is_disabled(handle)

  # @spec is_editable(ElementHandle.t()) :: {:ok, boolean()}
  # def is_editable(handle)

  # @spec is_enabled(ElementHandle.t()) :: {:ok, boolean()}
  # def is_enabled(handle)

  # @spec is_hidden(ElementHandle.t()) :: {:ok, boolean()}
  # def is_hidden(handle)

  # ---

  @spec is_visible(t() | {:ok, t()}) :: {:ok, boolean()}
  def is_visible(handle)

  def is_visible(%ElementHandle{} = handle) do
    {:ok, result} = Channel.post(handle, :is_visible)
    {:ok, result == true}
  end

  # ---

  # @spec press(ElementHandle.t(), binary(), options()) :: :ok
  # def press(handle, key, options \\ %{})

  # ---

  @doc """
  Searches within an element for a DOM element matching the given selector.

  Finds an element matching the specified selector within the subtree of the
  `ElementHandle`. See "working with selectors (guide)" for more details.

  If no elements match the selector, returns `nil`.
  """
  @spec query_selector(t(), binary()) :: ElementHandle.t() | nil
  def query_selector(handle, selector)

  def query_selector(%ElementHandle{} = handle, selector) do
    handle |> Channel.post!(:query_selector, %{selector: selector})
  end

  defdelegate q(handle, selector), to: __MODULE__, as: :query_selector

  # ---

  # @spec query_selector_all(ElementHandle.t(), binary()) :: {:ok, [ElementHandle.t()]}
  # def query_selector_all(handle, selector)
  # defdelegate qq(handle, selector), to: __MODULE__, as: :query_selector_all

  # ---

  @spec screenshot(ElementHandle.t(), options()) :: {:ok, binary()}
  def screenshot(%ElementHandle{} = handle, options \\ %{}) do
    case Map.pop(options, :path) do
      {nil, params} ->
        {:ok, encoded} = Channel.post(handle, :screenshot, params)
        Base.decode64(encoded)

      {path, params} ->
        [_, filetype] = String.split(path, ".")

        {:ok, encoded} = Channel.post(handle, :screenshot, Map.put(params, :type, filetype))
        {:ok, decoded} = Base.decode64(encoded)
        File.write!(path, decoded)
        {:ok, decoded}
    end
  end

  @spec scroll_into_view(ElementHandle.t(), options()) :: :ok
  def scroll_into_view(%ElementHandle{} = handle, options \\ %{}) do
    {:ok, _} = Channel.post(handle, :scroll_into_view_if_needed, options)
    :ok
  end

  # ---

  # @spec select_option(ElementHandle.t(), selection(), options()) :: {:ok, [binary()]}
  # def select_option(handle, values, options \\ %{})

  # ---

  @spec select_text(ElementHandle.t(), options()) :: :ok
  def select_text(handle, options \\ %{}) do
    {:ok, _} = Channel.post(handle, :select_text, options)
    :ok
  end

  # ---

  # @spec set_checked(ElementHandle.t(), boolean(), options()) :: :ok
  # def set_checked(handle, checked, options \\ %{})

  # @spec set_input_files(ElementHandle.t(), file_list(), options()) :: :ok
  # def set_input_files(handle, files, options \\ %{})

  # @spec tap(ElementHandle.t(), options()) :: :ok
  # def tap(handle, options \\ %{})

  # ---

  @doc """
  Returns the `node.textContent` (all text within the element).
  """
  @spec text_content(t()) :: binary() | nil
  def text_content(handle)

  def text_content(%ElementHandle{} = handle) do
    handle |> Channel.post!(:text_content)
  end

  # ---

  # @spec type(ElementHandle.t(), binary(), options()) :: :ok
  # def type(handle, text, options \\ %{})

  # @spec uncheck(ElementHandle.t(), options()) :: :ok
  # def uncheck(handle, options \\ %{})

  # @spec wait_for_element_state(ElementHandle.t(), state(), options()) :: :ok
  # def wait_for_element_state(handle, state, options \\ %{})

  # @spec wait_for_selector(ElementHandle.t(), binary(), options()) :: {:ok, ElementHandle.t() | nil}
  # def wait_for_selector(handle, selector, options \\ %{})

  # ---
end
