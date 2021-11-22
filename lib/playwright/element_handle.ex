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

  > NOTE
  >
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

  use Playwright.ChannelOwner, fields: [:preview]
  alias Playwright.{ChannelOwner, ElementHandle, Frame}
  alias Playwright.Runner.{Channel, Helpers}

  @typedoc "A map/struct providing call options"
  @type options :: map()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%ElementHandle{} = owner, _initializer) do
    Channel.bind(owner, :preview_updated, fn %{params: params} = event ->
      {:patch, %{event.target | preview: params.preview}}
    end)
  end

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec bounding_box(ElementHandle.t()) :: {:ok, map() | nil}
  # def bounding_box(owner)

  # @spec check(ElementHandle.t(), options()) :: :ok
  # def check(owner, options \\ %{})

  # @spec click(ElementHandle.t(), options()) :: :ok
  # def click(owner, options \\ %{})

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
  def click(owner, _options \\ %{})

  def click(%ElementHandle{} = owner, _options) do
    {:ok, _} = Channel.post(owner, :click)
    :ok
  end

  def click({:ok, owner}, options) do
    click(owner, options)
  end

  @doc """
  Returns the `Playwright.Frame` for element handles referencing iframe nodes,
  or `nil otherwise.
  """
  @spec content_frame(t() | {:ok, t()}) :: {:ok, Frame.t() | nil}
  def content_frame(owner)

  def content_frame(%ElementHandle{} = owner) do
    Channel.post(owner, :content_frame)
  end

  def content_frame({:ok, owner}) do
    content_frame(owner)
  end

  # ---

  # @spec dblclick(ElementHandle.t(), options()) :: :ok
  # def dblclick(owner, options \\ %{})

  # @spec dispatch_event(ElementHandle.t(), event(), evaluation_argument()) :: :ok
  # def dispatch_event(owner, type, arg \\ nil)

  # ---

  # TODO: move this to `JSHandle`, matching the official API.
  @doc false
  def evaluate_handle(owner, expression, arg \\ nil)

  def evaluate_handle(%ElementHandle{} = owner, expression, arg) do
    params = %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    }

    Channel.post(owner, :evaluate_expression_handle, params)
  end

  def evaluate_handle({:ok, owner}, expression, arg) do
    evaluate_handle(owner, expression, arg)
  end

  # ---

  # @spec fill(ElementHandle.t(), binary(), options()) :: :ok
  # def fill(owner, value, options \\ %{})

  # @spec focus(ElementHandle.t()) :: :ok
  # def focus(owner)

  # ---

  @doc """
  Returns the value of an element's attribute.
  """
  @spec get_attribute(t() | {:ok, t()}, binary()) :: {:ok, binary() | nil}
  def get_attribute(owner, name)

  def get_attribute(%ElementHandle{} = owner, name) do
    Channel.post(owner, :get_attribute, %{name: name})
  end

  def get_attribute({:ok, owner}, name) do
    get_attribute(owner, name)
  end

  # ---

  # @spec hover(ElementHandle.t(), options()) :: :ok
  # def hover(owner, options \\ %{})

  # @spec inner_html(ElementHandle.t()) :: {:ok, binary() | nil}
  # def inner_html(owner)

  # @spec inner_text(ElementHandle.t()) :: {:ok, binary() | nil}
  # def inner_text(owner)

  # @spec input_value(ElementHandle.t(), options()) :: {:ok, binary()}
  # def input_value(owner, options)

  # @spec is_checked(ElementHandle.t()) :: {:ok, boolean()}
  # def is_checked(owner)

  # @spec is_disabled(ElementHandle.t()) :: {:ok, boolean()}
  # def is_disabled(owner)

  # @spec is_editable(ElementHandle.t()) :: {:ok, boolean()}
  # def is_editable(owner)

  # @spec is_enabled(ElementHandle.t()) :: {:ok, boolean()}
  # def is_enabled(owner)

  # @spec is_hidden(ElementHandle.t()) :: {:ok, boolean()}
  # def is_hidden(owner)

  # @spec is_visible(ElementHandle.t()) :: {:ok, boolean()}
  # def is_visible(owner)

  # @spec press(ElementHandle.t(), binary(), options()) :: :ok
  # def press(owner, key, options \\ %{})

  # ---

  @doc """
  Searches within an element for a DOM element matching the given selector.

  Finds an element matching the specified selector within the subtree of the
  `ElementHandle`. See "working with selectors (guide)" for more details.

  If no elements match the selector, returns `nil`.
  """
  @spec query_selector(t() | {:ok, t()}, binary()) :: {:ok, ElementHandle.t() | nil}
  def query_selector(owner, selector)

  def query_selector(%ElementHandle{} = owner, selector) do
    owner |> Channel.post(:query_selector, %{selector: selector})
  end

  def query_selector({:ok, owner}, selector) do
    query_selector(owner, selector)
  end

  defdelegate q(owner, selector), to: __MODULE__, as: :query_selector

  # ---

  # @spec query_selector_all(ElementHandle.t(), binary()) :: {:ok, [ElementHandle.t()]}
  # def query_selector_all(owner, selector)
  # defdelegate qq(owner, selector), to: __MODULE__, as: :query_selector_all

  # @spec screenshot(ElementHandle.t(), options()) :: {:ok, binary()}
  # def screenshot(owner, options \\ %{})

  # @spec scroll_into_view_if_needed(ElementHandle.t(), options()) :: :ok
  # def scroll_into_view_if_needed(owner, options \\ %{})

  # @spec select_option(ElementHandle.t(), selection(), options()) :: {:ok, [binary()]}
  # def select_option(owner, values, options \\ %{})

  # @spec select_option(ElementHandle.t(), options()) :: :ok
  # def select_option(owner, options \\ %{})

  # @spec set_checked(ElementHandle.t(), boolean(), options()) :: :ok
  # def set_checked(owner, checked, options \\ %{})

  # @spec set_input_files(ElementHandle.t(), file_list(), options()) :: :ok
  # def set_input_files(owner, files, options \\ %{})

  # @spec tap(ElementHandle.t(), options()) :: :ok
  # def tap(owner, options \\ %{})

  # ---

  @doc """
  Returns the `node.textContent` (all text within the element).
  """
  @spec text_content(t() | {:ok, t()}) :: {:ok, binary() | nil}
  def text_content(owner)

  def text_content(%ElementHandle{} = owner) do
    owner |> Channel.post(:text_content)
  end

  def text_content({:ok, owner}) do
    text_content(owner)
  end

  # ---

  # @spec type(ElementHandle.t(), binary(), options()) :: :ok
  # def type(owner, text, options \\ %{})

  # @spec uncheck(ElementHandle.t(), options()) :: :ok
  # def uncheck(owner, options \\ %{})

  # @spec wait_for_element_state(ElementHandle.t(), state(), options()) :: :ok
  # def wait_for_element_state(owner, state, options \\ %{})

  # @spec wait_for_selector(ElementHandle.t(), binary(), options()) :: {:ok, ElementHandle.t() | nil}
  # def wait_for_selector(owner, selector, options \\ %{})

  # ---
end
