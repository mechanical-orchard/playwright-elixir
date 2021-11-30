defmodule Playwright.Page do
  @moduledoc """
  `Page` provides methods to interact with a single tab in a
  `Playwright.Browser`, or an [extension background page](https://developer.chrome.com/extensions/background_pages)
  in Chromium.

  One `Playwright.Browser` instance might have multiple `Page` instances.

  ## Example

  Create a page, navigate it to a URL, and save a screenshot:

      {:ok, page} = Browser.new_page(browser)
      {:ok, resp} = Page.goto(page, "https://example.com")

      {:ok _} = Page.screenshot(page, %{path: "screenshot.png"})

      :ok = Page.close(page)

  The Page module is capable of hanlding various emitted events (described below).

  ## Example

  Log a message for a single page load event (WIP: `once` is not yet implemented):

      Page.once(page, :load, fn e ->
        IO.puts("page loaded!")
      end)

  Unsubscribe from events with the `remove_lstener` function (WIP: `remove_listener` is not yet implemented):

      def log_request(request) do
        IO.inspect(label: "A request was made")
      end

      Page.on(page, :request, fn e ->
        log_request(e.pages.request)
      end)

      Page.remove_listener(page, log_request)
  """
  use Playwright.ChannelOwner

  alias Playwright.{BrowserContext, Frame, Page}
  alias Playwright.ChannelOwner
  alias Playwright.Runner.Helpers

  @property :is_closed
  @property :main_frame
  @property :owned_context

  @type function_or_options :: fun() | options() | nil
  @type options :: map()

  require Logger

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, _intializer) do
    Channel.bind(owner, :close, fn event ->
      {:patch, %{event.target | is_closed: true}}
    end)

    {:ok, owner}
  end

  # delegates (should these be reworked as a Protocol?)
  # ---------------------------------------------------------------------------

  # defdelegate add_script_tag(page, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate add_style_tag(page, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate check(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  defdelegate click(page, selector, options \\ %{}),
    to: Playwright.Frame

  # defdelegate dispatch_event(page, selector, type, event_init \\ nil, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate drag_and_drop(page, source, target, options \\ %{}),
  #   to: Playwright.Frame

  defdelegate evaluate(page, expression, arg \\ nil),
    to: Playwright.Frame

  defdelegate evaluate_handle(page, expression, arg \\ nil),
    to: Playwright.Frame

  defdelegate expect_event(owner, event, trigger),
    to: Playwright.BrowserContext

  # defdelegate expect_navigation(owner, event, trigger),
  #   to: Playwright.Frame
  # ... also wait_for_navigation

  defdelegate fill(page, selector, value),
    to: Playwright.Frame

  defdelegate get_attribute(page, selector, name, options \\ %{}),
    to: Playwright.Frame

  defdelegate goto(page, url, params \\ %{}),
    to: Playwright.Frame

  # defdelegate hover(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate inner_html(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate inner_text(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate input_value(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate is_checked(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate is_disabled(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate is_editable(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate is_enabled(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate is_hidden(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate is_visible(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate locator(page, selector),
  #   to: Playwright.Frame

  defdelegate press(page, selector, key, options \\ %{}),
    to: Playwright.Frame

  defdelegate q(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate q!(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate query_selector(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate query_selector!(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate qq(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate query_selector_all(page, selector, options \\ %{}),
    to: Playwright.Frame

  # defdelegate pause(page),
  #   to: Playwright.BrowserContext

  defdelegate set_content(page, html, options \\ %{}),
    to: Playwright.Frame

  # defdelegate set_input_files(page, selector, files, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate tap(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  defdelegate text_content(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate title(page),
    to: Playwright.Frame

  # defdelegate type(page, selector, text, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate uncheck(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  defdelegate url(page),
    to: Playwright.Frame

  # defdelegate wait_for_function(page, expression, arg \\ nil, options \\ %{}),
  #   to: Playwright.Frame

  defdelegate wait_for_selector(page, selector, options \\ %{}),
    to: Playwright.Frame

  # defdelegate wait_for_timeout(page, timeout),
  #   to: Playwright.Frame

  # defdelegate wait_for_url(page, url, options \\ %{}),
  #   to: Playwright.Frame

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec add_init_script(Page.t(), binary(), options()) :: :ok
  # def add_init_script(owner, script, options \\ %{})

  # @spec bring_to_front(Page.t()) :: :ok
  # def bring_to_front(owner)

  # ---

  @doc """
  Closes the `Page`.

  If the `Page` has an "owned context" (1-to-1 co-dependency with a
  `Playwright.BrowserContext`), that context is closed as well.

  If `option: run_before_unload` is false, does not run any unload handlers and
  waits for the page to be closed. If `option: run_before_unload` is `true`
  the function will run unload handlers, but will not wait for the page to
  close. By default, `Playwright.Page.close/1` does not run `:beforeunload`
  handlers.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name          | type   |             | description |
  | ------------------- | ------ | ----------- | ----------- |
  | `run_before_unload` | option | `boolean()` | Whether to run the before unload page handlers. `(default: false)` |

  ## NOTE

  > if `option: run_before_unload` is passed as `true`, a `:beforeunload`
  > dialog might be summoned and should be handled manually via
  > `Playwright.Page.on/3`.
  """
  @spec close(t() | {:ok, t()}, options()) :: :ok
  def close(owner, options \\ %{})

  def close(%Page{} = owner, options) do
    Channel.post(owner, :close, options)

    # NOTE: this *might* prefer to be done on `__dispose__`
    # ...OR, `.on(_, "close", _)`
    if owner.owned_context do
      context(owner) |> BrowserContext.close()
    end

    :ok
  end

  def close({:ok, owner}, options) do
    close(owner, options)
  end

  @doc """
  Get the full HTML contents of the page, including the doctype.
  """
  @spec content(t() | {:ok, t()}) :: {:ok, binary()}
  def content(owner)

  def content(%Page{} = owner) do
    Channel.post(owner, :content)
  end

  def content({:ok, owner}) do
    content(owner)
  end

  @doc """
  Get the `Playwright.BrowserContext` that the page belongs to.
  """
  @spec context(t() | {:ok, t()}) :: BrowserContext.t()
  def context(owner)

  def context(%Page{} = owner) do
    {:ok, ctx} = Channel.find(owner, owner.parent)
    ctx
  end

  def context({:ok, owner}) do
    context(owner)
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.dblclick/3`.
  """
  @spec dblclick(t() | {:ok, t()}, binary(), options()) :: :ok
  def dblclick(page, selector, options \\ %{})

  def dblclick(%Page{} = page, selector, options) do
    main_frame(page) |> Frame.dblclick(selector, options)
  end

  def dblclick({:ok, page}, selector, options) do
    dblclick(page, selector, options)
  end

  # ---

  # @spec emulate_media(Page.t(), options()) :: :ok
  # def emulate_media(page, options \\ %{})

  # ---

  @spec eval_on_selector(Page.t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(owner, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Page{} = owner, selector, expression, arg, options) do
    main_frame(owner)
    |> Frame.eval_on_selector(selector, expression, arg, options)
  end

  def eval_on_selector({:ok, owner}, selector, expression, arg, options) do
    eval_on_selector(owner, selector, expression, arg, options)
  end

  # ---

  # @spec expect_event(Page.t(), atom() | binary(), function(), options()) :: :ok
  # def expect_event(page, event, predicate \\ nil, options \\ %{})
  # ...defdelegate wait_for_event

  # @spec expect_request(Page.t(), binary() | function(), options()) :: :ok
  # def expect_request(page, url_or_predicate, options \\ %{})
  # ...defdelegate wait_for_request

  # @spec expect_response(Page.t(), binary() | function(), options()) :: :ok
  # def expect_response(page, url_or_predicate, options \\ %{})
  # ...defdelegate wait_for_response

  # @spec expose_binding(Page.t(), binary(), function(), options()) :: :ok
  # def expose_binding(page, name, callback, options \\ %{})

  # @spec expose_function(Page.t(), binary(), function()) :: :ok
  # def expose_function(page, name, callback)

  # ---

  @doc """
  A shortcut for the main frame's `Playwright.Frame.focus/3`.
  """
  @spec focus(t(), binary(), options()) :: :ok
  def focus(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.focus(selector, options)
  end

  # ---

  # @spec frame(Page.t(), binary()) :: Frame.t() | nil
  # def frame(page, selector)

  # @spec frames(Page.t()) :: [Frame.t()]
  # def frames(page)

  # @spec frame_locator(Page.t(), binary()) :: FrameLocator.t()
  # def frame_locator(page, selector)

  # @spec go_back(Page.t(), options()) :: {:ok, Response.t() | nil}
  # def go_back(page, options \\ %{})

  # @spec go_forward(Page.t(), options()) :: {:ok, Response.t() | nil}
  # def go_forward(page, options \\ %{})

  # ---

  @doc """
  A shortcut for the main frame's `Playwright.Frame.hover/2`.
  """
  def hover(%Page{} = page, selector) do
    main_frame(page) |> Frame.hover(selector)
  end

  # ---

  # @spec is_closed(Page.t()) :: boolean()
  # def is_closed(page)

  # ---

  @spec locator(t(), binary()) :: Playwright.Locator.t()
  def locator(%Page{} = page, selector) do
    Playwright.Locator.new(page, selector)
  end

  # NOTE: these events will be recv'd from Playwright server with
  # the parent BrowserContext as the context/bound :guid. So, we need to
  # add our handlers there, on that (BrowserContext) parent.
  def on(%Page{} = owner, event, callback)
      when event in [:request, :response, :request_finished, "request", "response", "requestFinished"] do
    context(owner) |> Channel.bind(event, callback)
  end

  def on(%Page{} = owner, event, callback) do
    Channel.bind(owner, event, callback)
  end

  def on({:ok, owner}, event, callback) do
    on(owner, event, callback)
  end

  # ---

  # @spec opener(Page.t()) :: {:ok, Page.t() | nil}
  # def opener(page)

  # @spec pdf(Page.t(), options()) :: {:ok, binary()}
  # def pdf(page, options \\ %{})

  # @spec reload(Page.t(), options()) :: {:ok, Response.t() | nil}
  # def reload(page, options \\ %{})

  # ---

  @spec route(Page.t(), binary(), function(), map()) :: {atom(), Page.t()}
  def route(owner, pattern, handler, options \\ %{})

  def route(%Page{} = owner, pattern, handler, _options) do
    matcher = Helpers.URLMatcher.new(pattern)

    if Enum.empty?(owner.listeners["route"] || []) do
      Channel.post(owner, :set_network_interception_enabled, %{enabled: true})
    end

    Channel.bind(owner, :route, &Page.exec_callback_on_route(&1, matcher, handler))
  end

  def route({:ok, owner}, pattern, handler, options) do
    route(owner, pattern, handler, options)
  end

  @spec screenshot(Page.t(), options()) :: {:ok, binary()}
  def screenshot(owner, options \\ %{})

  def screenshot(%Page{} = owner, options) do
    case Map.pop(options, :path) do
      {nil, params} ->
        Channel.post(owner, :screenshot, params)

      {path, params} ->
        [_, filetype] = String.split(path, ".")

        {:ok, data} = Channel.post(owner, :screenshot, Map.put(params, :type, filetype))
        File.write!(path, Base.decode64!(data))
        {:ok, data}
    end
  end

  def screenshot({:ok, owner}, options) do
    screenshot(owner, options)
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.select_option/4`.
  """
  @spec select_option(t(), binary(), any(), options()) :: {:ok, [binary()]}
  def select_option(%Page{} = page, selector, values \\ nil, options \\ %{}) do
    main_frame(page) |> Frame.select_option(selector, values, options)
  end

  # ---

  # @spec set_checked(Page.t(), binary(), boolean(), options()) :: :ok
  # def set_checked(page, selector, checked, options \\ %{})

  # NOTE: these 2 are good examples of functions that should `cast` instead of `call`.
  # ...
  # @spec set_default_navigation_timeout(Page.t(), number()) :: nil (???)
  # def set_default_navigation_timeout(page, timeout)

  # @spec set_default_timeout(Page.t(), number()) :: nil (???)
  # def set_default_timeout(page, timeout)

  # @spec set_extra_http_headers(Page.t(), map()) :: :ok
  # def set_extra_http_headers(page, headers)

  # @spec set_viewport_size(Page.t(), dimensions()) :: :ok
  # def set_viewport_size(page, dimensions)

  # @spec unroute(Page.t(), function()) :: :ok
  # def unroute(owner, handler \\ nil)

  # @spec video(Page.t()) :: Video.t() | nil
  # def video(owner, handler \\ nil)

  # @spec viewport_size(Page.t()) :: dimensions() | nil
  # def viewport_size(owner)

  # ---

  @spec wait_for_load_state(Page.t(), binary(), options()) :: {:ok, Page.t()}
  def wait_for_load_state(owner, state \\ "load", options \\ %{})

  def wait_for_load_state(%Page{} = owner, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    Logger.warn("Page.wait_for_load_state (not fully implemented)")

    {:ok, _} =
      main_frame(owner)
      |> Frame.wait_for_load_state(state)

    {:ok, owner}
  end

  def wait_for_load_state(%Page{} = owner, state, options) when is_binary(state) do
    wait_for_load_state(owner, state, options)
  end

  def wait_for_load_state(%Page{} = owner, options, _) when is_map(options) do
    wait_for_load_state(owner, "load", options)
  end

  # ---

  # @spec workers(Page.t()) :: [Worker.t()]
  # def workers(owner)

  # ---

  # ... (like Locator?)
  # def accessibility(page)
  # def coverage(page)
  # def keyboard(page)
  # def mouse(page)
  # def request(page)
  # def touchscreen(page)

  # ---

  # private
  # ---------------------------------------------------------------------------

  @doc false
  def exec_callback_on_route(%{params: %{request: request, route: route}}, matcher, callback) do
    if Helpers.URLMatcher.matches(matcher, request.url) do
      Task.start_link(fn ->
        callback.(route, request)
      end)
    end
  end
end
