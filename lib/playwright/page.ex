defmodule Playwright.Page do
  @moduledoc """
  `Page` provides methods to interact with a single tab in a
  `Playwright.Browser`, or an [extension background page](https://developer.chrome.com/extensions/background_pages)
  in Chromium.

  One `Playwright.Browser` instance might have multiple `Page` instances.

  ## Example

  Create a page, navigate it to a URL, and save a screenshot:

      page = Browser.new_page(browser)
      resp = Page.goto(page, "https://example.com")

      Page.screenshot(page, %{path: "screenshot.png"})
      :ok = Page.close(page)

  The Page module is capable of handling various emitted events (described below).

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
  alias Playwright.Helpers

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
  def init(%Page{session: session} = page, _intializer) do
    Channel.bind(session, {:guid, page.guid}, :close, fn event ->
      {:patch, %{event.target | is_closed: true}}
    end)

    Channel.bind(session, {:guid, page.guid}, :route, fn %{target: target} = e ->
      on_route(target, e)
      # NOTE: will patch here
    end)

    {:ok, %{page | routes: []}}
  end

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

  | key/name  | type   |                       | description |
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
  def add_init_script(%Page{session: session} = page, script) when is_binary(script) do
    params = %{source: script}
    Channel.post(session, {:guid, page.guid}, :add_init_script, params)
  end

  def add_init_script(%Page{} = page, %{path: path} = script) when is_map(script) do
    add_init_script(page, File.read!(path))
  end

  # ---

  # @spec bring_to_front(t()) :: :ok
  # def bring_to_front(owner)

  # ---

  @spec click(t(), binary(), options()) :: :ok
  def click(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.click(selector, options)
  end

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

  | key/name          | type   |             | description |
  | ------------------- | ------ | ----------- | ----------- |
  | `run_before_unload` | option | `boolean()` | Whether to run the before unload page handlers. `(default: false)` |

  ## NOTE

  > if `option: run_before_unload` is passed as `true`, a `:beforeunload`
  > dialog might be summoned and should be handled manually via
  > `Playwright.Page.on/3`.
  """
  @spec close(t(), options()) :: :ok
  def close(%Page{session: session} = page, options \\ %{}) do
    Channel.post(session, {:guid, page.guid}, :close, options)

    # NOTE: this *might* prefer to be done on `__dispose__`
    # ...OR, `.on(_, "close", _)`
    if page.owned_context do
      context(page) |> BrowserContext.close()
    end

    :ok
  end

  # @doc """
  # Get the full HTML contents of the page, including the doctype.
  # """
  # @spec content(t()) :: binary()
  # def content(%Page{session: session} = page) do
  #   Channel.post(session, {:guid, page.guid}, :content)
  # end

  @doc """
  Get the `Playwright.BrowserContext` that the page belongs to.
  """
  @spec context(t()) :: BrowserContext.t()
  def context(owner)

  def context(%Page{session: session} = owner) do
    Channel.find(session, {:guid, owner.parent.guid})
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.dblclick/3`.
  """
  @spec dblclick(t(), binary(), options()) :: :ok
  def dblclick(page, selector, options \\ %{})

  def dblclick(%Page{} = page, selector, options) do
    main_frame(page) |> Frame.dblclick(selector, options)
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
  def eval_on_selector(%Page{} = owner, selector, expression, arg \\ nil, options \\ %{}) do
    main_frame(owner)
    |> Frame.eval_on_selector(selector, expression, arg, options)
  end

  @spec evaluate(t(), expression(), any()) :: serializable()
  def evaluate(page, expression, arg \\ nil)

  def evaluate(%Page{} = page, expression, arg) do
    main_frame(page) |> Frame.evaluate(expression, arg)
  end

  @spec evaluate_handle(t(), expression(), any()) :: serializable()
  def evaluate_handle(%Page{} = page, expression, arg \\ nil) do
    main_frame(page) |> Frame.evaluate_handle(expression, arg)
  end

  # @spec expect_event(t(), atom() | binary(), function(), any(), any()) :: Playwright.Channel.Event.t()
  # def expect_event(page, event, trigger, predicate \\ nil, options \\ %{})

  # def expect_event(%Page{} = page, event, trigger, predicate, options) do
  #   context(page) |> BrowserContext.expect_event(event, trigger, predicate, options)
  # end

  def expect_event(page, event, options \\ %{}, trigger \\ nil)

  def expect_event(%Page{} = page, event, options, trigger) do
    context(page) |> BrowserContext.expect_event(event, options, trigger)
  end

  # ---

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

  @spec fill(t(), binary(), binary(), options()) :: :ok
  def fill(%Page{} = page, selector, value, options \\ %{}) do
    main_frame(page) |> Frame.fill(selector, value, options)
  end

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
    Channel.list(page.session, {:guid, page.guid}, "Frame")
  end

  # ---

  # @spec frame_locator(t(), binary()) :: FrameLocator.t()
  # def frame_locator(page, selector)

  # ---

  @spec get_attribute(t(), binary(), binary(), map()) :: binary() | nil
  def get_attribute(%Page{} = page, selector, name, options \\ %{}) do
    main_frame(page) |> Frame.get_attribute(selector, name, options)
  end

  # ---

  # @spec go_back(t(), options()) :: Response.t() | nil
  # def go_back(page, options \\ %{})

  # @spec go_forward(t(), options()) :: Response.t() | nil
  # def go_forward(page, options \\ %{})

  # ---

  @spec goto(t(), binary(), options()) :: Response.t() | nil | {:error, term()}
  def goto(%Page{} = page, url, options \\ %{}) do
    main_frame(page) |> Frame.goto(url, options)
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

  # ---

  @spec request(t()) :: Playwright.APIRequestContext.t()
  def request(%Page{session: session} = page) do
    Channel.list(session, {:guid, page.owned_context.browser.guid}, "APIRequestContext")
    |> List.first()
  end

  # NOTE: these events will be recv'd from Playwright server with
  # the parent BrowserContext as the context/bound :guid. So, we need to
  # add our handlers there, on that (BrowserContext) parent.
  def on(%Page{session: session} = page, event, callback)
      when event in [:request, :response, :request_finished, "request", "response", "requestFinished"] do
    Channel.bind(session, {:guid, context(page).guid}, event, callback)
  end

  def on(%Page{session: session} = page, event, callback) do
    Channel.bind(session, {:guid, page.guid}, event, callback)
  end

  # ---

  # @spec opener(t()) :: Page.t() | nil
  # def opener(page)

  # @spec pdf(t(), options()) :: binary()
  # def pdf(page, options \\ %{})

  # ---

  @spec press(t(), binary(), binary(), options()) :: :ok
  def press(%Page{} = page, selector, key, options \\ %{}) do
    main_frame(page) |> Frame.press(selector, key, options)
  end

  @spec query_selector(t(), selector(), options()) :: ElementHandle.t() | nil | {:error, :timeout}
  def query_selector(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.query_selector(selector, options)
  end

  defdelegate q(page, selector, options \\ %{}), to: __MODULE__, as: :query_selector

  @spec query_selector_all(t(), binary(), map()) :: [ElementHandle.t()]
  def query_selector_all(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.query_selector_all(selector, options)
  end

  defdelegate qq(page, selector, options \\ %{}), to: __MODULE__, as: :query_selector_all

  @doc """
  Reloads the current page.

  Reloads in the same way as if the user had triggered a browser refresh.

  Returns the main resource response. In case of multiple redirects, the
  navigation will resolve with the response of the last redirect.

  ## Returns

    - `Playwright.Response.t() | nil`

  ## Arguments

  | key/name    | type   |            | description |
  | ------------- | ------ | ---------- | ----------- |
  | `:timeout`    | option | `number()` | Maximum time in milliseconds. Pass `0` to disable timeout. The default value can be changed via `Playwright.BrowserContext.set_default_timeout/2` or `Playwright.Page.set_default_timeout/2`. `(default: 30 seconds)` |
  | `:wait_until` | option | `binary()` | "load", "domcontentloaded", "networkidle", or "commit". When to consider the operation as having succeeded. `(default: "load")` |

  ## On Wait Events

  - `domcontentloaded` - consider operation to be finished when the `DOMContentLoaded` event is fired.
  - `load` - consider operation to be finished when the `load` event is fired.
  - `networkidle` - consider operation to be finished when there are no network connections for at least `500 ms`.
  - `commit` - consider operation to be finished when network response is received and the document started loading.
  """
  @spec reload(t(), options()) :: Response.t() | nil
  def reload(%Page{session: session} = page, options \\ %{}) do
    Channel.post(session, {:guid, page.guid}, :reload, options)
  end

  @spec route(t(), binary(), function(), map()) :: :ok
  def route(page, pattern, handler, options \\ %{})

  def route(%Page{session: session} = page, pattern, handler, _options) do
    with_latest(page, fn page ->
      matcher = Helpers.URLMatcher.new(pattern)
      handler = Helpers.RouteHandler.new(matcher, handler)
      routes = page.routes

      if Enum.empty?(routes) do
        Channel.post(session, {:guid, page.guid}, :set_network_interception_enabled, %{enabled: true})
      end

      Channel.patch(session, {:guid, page.guid}, %{routes: [handler | routes]})
      :ok
    end)
  end

  @spec screenshot(t(), options()) :: binary()
  def screenshot(%Page{session: session} = page, options \\ %{}) do
    case Map.pop(options, :path) do
      {nil, params} ->
        Channel.post(session, {:guid, page.guid}, :screenshot, params)

      {path, params} ->
        [_, filetype] = String.split(path, ".")

        data = Channel.post(session, {:guid, page.guid}, :screenshot, Map.put(params, :type, filetype))
        File.write!(path, Base.decode64!(data))
        data
    end
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.select_option/4`.
  """
  @spec select_option(t(), binary(), any(), options()) :: [binary()]
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
  def set_viewport_size(%Page{session: session} = page, dimensions) do
    Channel.post(session, {:guid, page.guid}, :set_viewport_size, %{viewport_size: dimensions})
  end

  @spec text_content(t(), binary(), map()) :: binary() | nil
  def text_content(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.text_content(selector, options)
  end

  @spec title(t()) :: binary()
  def title(%Page{} = page) do
    main_frame(page) |> Frame.title()
  end

  # ---

  # @spec unroute(t(), function()) :: :ok
  # def unroute(owner, handler \\ nil)

  # ---

  @spec url(t()) :: binary()
  def url(%Page{} = page) do
    main_frame(page) |> Frame.url()
  end

  # ---

  # @spec video(t()) :: Video.t() | nil
  # def video(owner, handler \\ nil)

  # @spec viewport_size(t()) :: dimensions() | nil
  # def viewport_size(owner)

  # ---

  @spec wait_for_load_state(t(), binary(), options()) :: Page.t()
  def wait_for_load_state(page, state \\ "load", options \\ %{})

  def wait_for_load_state(%Page{} = page, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    main_frame(page) |> Frame.wait_for_load_state(state)
    page
  end

  def wait_for_load_state(%Page{} = page, state, options) when is_binary(state) do
    wait_for_load_state(page, state, options)
  end

  def wait_for_load_state(%Page{} = page, options, _) when is_map(options) do
    wait_for_load_state(page, "load", options)
  end

  @spec wait_for_selector(t(), binary(), map()) :: ElementHandle.t() | nil
  def wait_for_selector(%Page{} = page, selector, options \\ %{}) do
    main_frame(page) |> Frame.wait_for_selector(selector, options)
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
