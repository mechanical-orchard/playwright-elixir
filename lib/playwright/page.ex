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

  alias Playwright.{BrowserContext, ElementHandle, Frame, Page, Response}
  alias Playwright.ChannelOwner
  alias Playwright.Runner.Helpers

  @property :is_closed
  @property :main_frame
  @property :owned_context
  @property :routes

  @type dimensions :: map()
  @type expression :: binary()
  @type function_or_options :: fun() | options() | nil
  @type options :: map()
  @type selector :: binary()
  @type serializable :: any()

  require Logger

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(page, _intializer) do
    Channel.bind(page, :close, fn event ->
      {:patch, %{event.target | is_closed: true}}
    end)

    Channel.bind(page, :route, fn %{target: target} = e ->
      on_route(target, e)
      # NOTE: will patch here
    end)

    {:ok, %{page | routes: []}}
  end

  # delegates (should these be reworked as a Protocol?)
  # ---------------------------------------------------------------------------

  # defdelegate add_style_tag(page, options \\ %{}),
  #   to: Playwright.Frame

  # defdelegate check(page, selector, options \\ %{}),
  #   to: Playwright.Frame

  defdelegate click(page, selector, options \\ %{}),
    to: Playwright.Frame

  # defdelegate drag_and_drop(page, source, target, options \\ %{}),
  #   to: Playwright.Frame

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

  defdelegate qq(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate query_selector_all(page, selector, options \\ %{}),
    to: Playwright.Frame

  # defdelegate pause(page),
  #   to: Playwright.BrowserContext

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

  @doc """
  Adds a script to be evaluated before other scripts.

  The script is evaluated in the following scenarios:

  - Whenever the page is navigated.
  - Whenever a child frame is attached or navigated. In this case, the script
    is evaluated in the context of the newly attached frame.

  The script is evaluated after the document is created but before any of its
  scripts are run. This is useful to amend the JavaScript environment, e.g. to
  seed `Math.random`.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name  | type   |                       | description |
  | ----------- | ------ | --------------------- | ----------- |
  | `script`    | param  | `binary()` or `map()` | As `binary()`: an inlined script to be evaluated; As `%{path: path}`: a path to a JavaScript file. |

  ## Example

  Overriding `Math.random` before the page loads:

      # preload.js
      Math.random = () => 42;

      Page.add_init_script(context, %{path: "preload.js"})

  ## Notes

  > While the official Node.js Playwright implementation supports an optional
  > `param: arg` for this function, the official Python implementation does
  > not. This implementation matches the Python for now.

  > The order of evaluation of multiple scripts installed via
  > `Playwright.BrowserContext.add_init_script/2` and
  > `Playwright.Page.add_init_script/2` is not defined.
  """
  @spec add_init_script(t(), binary() | map()) :: :ok
  def add_init_script(%Page{} = page, script) when is_binary(script) do
    params = %{source: script}
    Channel.post!(page, :add_init_script, params)
  end

  def add_init_script(%Page{} = page, %{path: path} = script) when is_map(script) do
    add_init_script(page, File.read!(path))
  end

  # ---

  # @spec bring_to_front(t()) :: :ok
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

  @doc """
  A shortcut for the main frame's `Playwright.Frame.dispatch_event/5`.
  """
  @spec dispatch_event(t(), binary(), atom() | binary(), Frame.evaluation_argument(), options()) :: :ok
  def dispatch_event(%Page{} = page, selector, type, event_init \\ nil, options \\ %{}) do
    main_frame(page) |> Frame.dispatch_event(selector, type, event_init, options)
  end

  # ---

  # @spec emulate_media(t(), options()) :: :ok
  # def emulate_media(page, options \\ %{})

  # ---

  @spec eval_on_selector(t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(owner, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Page{} = owner, selector, expression, arg, options) do
    main_frame(owner)
    |> Frame.eval_on_selector(selector, expression, arg, options)
  end

  def eval_on_selector({:ok, owner}, selector, expression, arg, options) do
    eval_on_selector(owner, selector, expression, arg, options)
  end

  @spec evaluate(t(), expression(), any()) :: serializable()
  def evaluate(page, expression, arg \\ nil)

  def evaluate(%Page{} = page, expression, arg) do
    main_frame(page) |> Frame.evaluate(expression, arg)
  end

  # ---

  # @spec expect_event(t(), atom() | binary(), function(), options()) :: :ok
  # def expect_event(page, event, predicate \\ nil, options \\ %{})
  # ...defdelegate wait_for_event

  # @spec expect_request(t(), binary() | function(), options()) :: :ok
  # def expect_request(page, url_or_predicate, options \\ %{})
  # ...defdelegate wait_for_request

  # @spec expect_response(t(), binary() | function(), options()) :: :ok
  # def expect_response(page, url_or_predicate, options \\ %{})
  # ...defdelegate wait_for_response

  # @spec expose_binding(t(), binary(), function(), options()) :: :ok
  # def expose_binding(page, name, callback, options \\ %{})

  # @spec expose_function(t(), binary(), function()) :: :ok
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

  # @spec frame(t(), binary()) :: Frame.t() | nil
  # def frame(page, selector)

  # ---

  @spec frames(t()) :: [Frame.t()]
  def frames(%Page{} = page) do
    Channel.all(page.connection, %{
      parent: page,
      type: "Frame"
    })
  end

  # ---

  # @spec frame_locator(t(), binary()) :: FrameLocator.t()
  # def frame_locator(page, selector)

  # @spec go_back(t(), options()) :: {:ok, Response.t() | nil}
  # def go_back(page, options \\ %{})

  # @spec go_forward(t(), options()) :: {:ok, Response.t() | nil}
  # def go_forward(page, options \\ %{})

  # ---

  @spec goto(t() | {:ok, t()}, binary(), options()) :: Response.t() | nil | {:error, term()}
  def goto(owner, url, options \\ %{})

  def goto(%Page{} = page, url, options) do
    main_frame(page) |> Frame.goto(url, options)
  end

  def goto({:ok, page}, url, options) do
    goto(page, url, options)
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.hover/2`.
  """
  def hover(%Page{} = page, selector) do
    main_frame(page) |> Frame.hover(selector)
  end

  # ---

  # @spec is_closed(t()) :: boolean()
  # def is_closed(page)

  # ---

  @spec locator(t(), selector()) :: Playwright.Locator.t()
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

  # @spec opener(t()) :: {:ok, Page.t() | nil}
  # def opener(page)

  # @spec pdf(t(), options()) :: {:ok, binary()}
  # def pdf(page, options \\ %{})

  # ---

  @spec query_selector(t(), selector(), options()) :: ElementHandle.t() | nil | {:error, :timeout}
  def query_selector(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.query_selector(selector, options)
  end

  defdelegate q(page, selector, options \\ %{}), to: __MODULE__, as: :query_selector

  @doc """
  Reloads the current page.

  Reloads in the same way as if the user had triggered a browser refresh.

  Returns the main resource response. In case of multiple redirects, the
  navigation will resolve with the response of the last redirect.

  ## Returns

    - `{:ok, Playwright.Response.t() | nil}`

  ## Arguments

  | key / name    | type   |            | description |
  | ------------- | ------ | ---------- | ----------- |
  | `:timeout`    | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:wait_until` | option | `binary()` | "load", "domcontentloaded", "networkidle", or "commit". When to consider the operation as having succeeded. `(default: "load")` |

  ## On Wait Events

  - `domcontentloaded` - consider operation to be finished when the `DOMContentLoaded` event is fired.
  - `load` - consider operation to be finished when the `load` event is fired.
  - `networkidle` - consider operation to be finished when there are no network connections for at least `500 ms`.
  - `commit` - consider operation to be finished when network response is received and the document started loading.
  """
  @spec reload(t(), options()) :: {:ok, Response.t() | nil}
  def reload(page, options \\ %{}) do
    Channel.post(page, :reload, options)
  end

  @spec route(t(), binary(), function(), map()) :: :ok
  def route(page, pattern, handler, options \\ %{})

  def route(%Page{} = page, pattern, handler, _options) do
    with_latest(page, fn page ->
      matcher = Helpers.URLMatcher.new(pattern)
      handler = Helpers.RouteHandler.new(matcher, handler)
      routes = page.routes

      if Enum.empty?(routes) do
        Channel.post(page, :set_network_interception_enabled, %{enabled: true})
      end

      Channel.patch(page.connection, page.guid, %{routes: [handler | routes]})
      :ok
    end)
  end

  @spec screenshot(t(), options()) :: {:ok, binary()}
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

  # @spec set_checked(t(), binary(), boolean(), options()) :: :ok
  # def set_checked(page, selector, checked, options \\ %{})

  # ---

  @spec set_content(t(), binary(), options()) :: :ok
  def set_content(%Page{} = page, html, options \\ %{}) do
    main_frame(page) |> Frame.set_content(html, options)
  end

  # NOTE: these 2 are good examples of functions that should `cast` instead of `call`.
  # ...
  # @spec set_default_navigation_timeout(t(), number()) :: nil (???)
  # def set_default_navigation_timeout(page, timeout)

  # @spec set_default_timeout(t(), number()) :: nil (???)
  # def set_default_timeout(page, timeout)

  # @spec set_extra_http_headers(t(), map()) :: :ok
  # def set_extra_http_headers(page, headers)

  # ---

  @spec set_viewport_size(t(), dimensions()) :: :ok
  def set_viewport_size(%Page{} = page, dimensions) do
    {:ok, _} = Channel.post(page, :set_viewport_size, %{viewport_size: dimensions})
    :ok
  end

  # ---

  # @spec unroute(t(), function()) :: :ok
  # def unroute(owner, handler \\ nil)

  # @spec video(t()) :: Video.t() | nil
  # def video(owner, handler \\ nil)

  # @spec viewport_size(t()) :: dimensions() | nil
  # def viewport_size(owner)

  # ---

  @spec wait_for_load_state(t(), binary(), options()) :: {:ok, Page.t()}
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

  # @spec workers(t()) :: [Worker.t()]
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

  defp on_route(page, %{params: %{request: request} = params} = _event) do
    Enum.reduce_while(page.routes, [], fn handler, acc ->
      if Helpers.RouteHandler.matches(handler, request.url) do
        Helpers.RouteHandler.handle(handler, params)
        # break
        {:halt, acc}
      else
        {:cont, [handler | acc]}
      end
    end)

    # task =
    #   Task.async(fn ->
    #     IO.puts("fetching context for page...")

    #     context(page)
    #     |> IO.inspect(label: "task context")
    #     |> BrowserContext.on_route(event)
    #   end)

    # Task.await(task)
  end
end
