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
  use Playwright.SDK.ChannelOwner

  alias Playwright.{BrowserContext, ElementHandle, Frame, Page, Response}
  alias Playwright.API.Error
  alias Playwright.SDK.{Channel, ChannelOwner, Helpers}

  @property :bindings
  @property :is_closed
  @property :main_frame
  @property :owned_context
  @property :routes

  # ---
  # @property :coverage
  # @property :keyboard
  # @property :mouse
  # @property :request
  # @property :touchscreen
  # ---

  @type dimensions :: map()
  @type expression :: binary()
  @type function_or_options :: fun() | options() | nil
  @type options :: map()
  @type selector :: binary()
  @type serializable :: any()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%Page{session: session} = page, _intializer) do
    Channel.bind(session, {:guid, page.guid}, :close, fn event ->
      {:patch, %{event.target | is_closed: true}}
    end)

    Channel.bind(session, {:guid, page.guid}, :binding_call, fn %{params: %{binding: binding}, target: target} ->
      on_binding(target, binding)
    end)

    Channel.bind(session, {:guid, page.guid}, :route, fn %{target: target} = e ->
      on_route(target, e)
      # NOTE: will patch here
    end)

    {:ok, %{page | bindings: %{}, routes: []}}
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

  | key/name    | type   |                       | description |
  | ----------- | ------ | --------------------- | ----------- |
  | `script`    | param  | `binary()` or `map()` | As `binary()`: an inlined script to be evaluated; As `%{path: path}`: a path to a JavaScript file. |

  ## Example

  Overriding `Math.random` before the page loads:

      # preload.js
      Math.random = () => 42;

      Page.add_init_script(page, %{path: "preload.js"})

  ## Notes

  > While the official Node.js Playwright implementation supports an optional
  > `param: arg` for this function, the official Python implementation does
  > not. This implementation matches the Python for now.

  > The order of evaluation of multiple scripts installed via
  > `Playwright.BrowserContext.add_init_script/2` and
  > `Playwright.Page.add_init_script/2` is not defined.
  """
  @spec add_init_script(t(), binary() | map()) :: t()
  def add_init_script(%Page{} = page, script) when is_binary(script) do
    Channel.post({page, :add_init_script}, %{source: script})
  end

  def add_init_script(%Page{} = page, %{path: path} = script) when is_map(script) do
    add_init_script(page, File.read!(path))
  end

  # ---

  # @spec add_locator_handler(t(), Locator.t(), (Locator.t() -> any()), options()) :: :ok
  # def add_locator_handler(page, locator, func, options \\ %{})

  # @spec add_script_tag(Page.t(), options()) :: ElementHandle.t()
  # def add_script_tag(page, options \\ %{})

  # @spec add_style_tag(Page.t(), options()) :: ElementHandle.t()
  # def add_style_tag(page, options \\ %{})

  # @spec bring_to_front(t()) :: :ok
  # def bring_to_front(page)

  # ---

  @spec click(t(), binary(), options()) :: t()
  def click(%Page{} = page, selector, options \\ %{}) do
    returning(page, fn ->
      main_frame(page) |> Frame.click(selector, options)
    end)
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

  | key/name            | type   |             | description |
  | ------------------- | ------ | ----------- | ----------- |
  | `run_before_unload` | option | `boolean()` | Whether to run the before unload page handlers. `(default: false)` |

  ## NOTE

  > if `option: run_before_unload` is passed as `true`, a `:beforeunload`
  > dialog might be summoned and should be handled manually via
  > `Playwright.Page.on/3`.
  """
  @spec close(t(), options()) :: :ok
  def close(%Page{session: session} = page, _options \\ %{}) do
    # A call to `close` will remove the item from the catalog. `Catalog.find`
    # here ensures that we do not `post` a 2nd `close`.
    case Channel.find(session, {:guid, page.guid}, %{timeout: 10}) do
      %Page{} ->
        Channel.close(page)

        # NOTE: this *might* prefer to be done on `__dispose__`
        # ...OR, `.on(_, "close", _)`
        if page.owned_context do
          context(page) |> BrowserContext.close()
        end

        :ok

      {:error, _} ->
        :ok
    end
  end

  # ---

  # @spec content(Page.t()) :: binary()
  # def content(page)

  # ---

  # @doc """
  # Get the full HTML contents of the page, including the doctype.
  # """
  # @spec content(t()) :: binary()
  # def content(%Page{session: session} = page)

  @doc """
  Get the `Playwright.BrowserContext` that the page belongs to.
  """
  @spec context(t()) :: BrowserContext.t()
  def context(page)

  def context(%Page{session: session} = page) do
    Channel.find(session, {:guid, page.parent.guid})
  end

  @spec content(t()) :: binary() | {:error, term()}
  def content(%Page{} = page) do
    main_frame(page) |> Frame.content()
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.dblclick/3`.
  """
  @spec dblclick(t(), binary(), options()) :: t()
  def dblclick(page, selector, options \\ %{})

  def dblclick(%Page{} = page, selector, options) do
    returning(page, fn ->
      main_frame(page) |> Frame.dblclick(selector, options)
    end)
  end

  @doc """
  A shortcut for the main frame's `Playwright.Frame.dispatch_event/5`.
  """
  @spec dispatch_event(t(), binary(), atom() | binary(), Frame.evaluation_argument(), options()) :: :ok
  def dispatch_event(%Page{} = page, selector, type, event_init \\ nil, options \\ %{}) do
    main_frame(page) |> Frame.dispatch_event(selector, type, event_init, options)
  end

  @spec drag_and_drop(Page.t(), binary(), binary(), options()) :: Page.t()
  def drag_and_drop(page, source, target, options \\ %{}) do
    with_latest(page, fn page ->
      main_frame(page) |> Frame.drag_and_drop(source, target, options)
    end)
  end

  # ---

  # @spec emulate_media(t(), options()) :: :ok
  # def emulate_media(page, options \\ %{})

  # ---

  @spec eval_on_selector(t(), binary(), binary(), term(), map()) :: term() | {:error, Error.t()}
  def eval_on_selector(%Page{} = page, selector, expression, arg \\ nil, options \\ %{}) do
    main_frame(page)
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

  # @spec expect_event(t(), atom() | binary(), function(), any(), any()) :: Playwright.SDK.Channel.Event.t()
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

  @doc """
  Adds a function called `param:name` on the `window` object of every frame in
  this page.

  When called, the function executes `param:callback` and resolves to the return
  value of the `callback`.

  The first argument to the `callback` function includes the following details
  about the caller:

      %{
        context: %Playwright.BrowserContext{},
        frame:   %Playwright.Frame{},
        page:    %Playwright.Page{}
      }

  See `Playwright.BrowserContext.expose_binding/4` for a similar,
  context-scoped version.
  """
  @spec expose_binding(t(), binary(), function(), options()) :: Page.t()
  def expose_binding(%Page{session: session} = page, name, callback, options \\ %{}) do
    Channel.patch(session, {:guid, page.guid}, %{bindings: Map.merge(page.bindings, %{name => callback})})
    Channel.post({page, :expose_binding}, Map.merge(%{name: name, needs_handle: false}, options))
  end

  @doc """
  Adds a function called `param:name` on the `window` object of every frame in
  the page.

  When called, the function executes `param:callback` and resolves to the return
  value of the `callback`.

  See `Playwright.BrowserContext.expose_function/3` for a similar,
  context-scoped version.
  """
  @spec expose_function(Page.t(), String.t(), function()) :: Page.t()
  def expose_function(page, name, callback) do
    expose_binding(page, name, fn _, args ->
      callback.(args)
    end)
  end

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

  # @spec get_by_alt_text(Page.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_alt_text(page, text, options \\ %{})

  # @spec get_by_label(Page.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_label(page, text, options \\ %{})

  # @spec get_by_placeholder(Page.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_placeholder(page, text, options \\ %{})

  # @spec get_by_role(Page.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_role(page, text, options \\ %{})

  # @spec get_by_test_id(Page.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_test_id(page, text, options \\ %{})

  @doc """
  Allows locating elements that contain given text.

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `text`     | param  | `binary()` | Text to locate the element for. |
  | `:exact`   | option | `boolean()`| Whether to find an exact match: case-sensitive and whole-string. Default to false. Ignored when locating by a regular expression. Note that exact match still trims whitespace. |
  """
  @spec get_by_text(Page.t(), binary(), %{optional(:exact) => boolean()}) :: Playwright.Locator.t() | nil
  def get_by_text(page, text, options \\ %{}) do
    main_frame(page) |> Frame.get_by_text(text, options)
  end

  # @spec get_by_title(Page.t(), binary(), options()) :: Playwright.Locator.t() | nil
  # def get_by_title(page, text, options \\ %{})

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

  # @spec main_frame(t()) :: Frame.t()
  # def main_frame(page)

  # @spec opener(t()) :: Frame.t() | nil
  # def opener(page)

  # @spec pause(t()) :: :ok
  # def pause(page)

  # ---

  # on(...):
  #   - close
  #   - console
  #   - crash
  #   - dialog
  #   - domcontentloaded
  #   - download
  #   - filechooser
  #   - frameattached
  #   - framedetached
  #   - framenavigated
  #   - load
  #   - pageerror
  #   - popup
  #   - requestfailed
  #   - websocket
  #   - worker

  def on(%Page{} = page, event, callback) when is_binary(event) do
    on(page, String.to_atom(event), callback)
  end

  # NOTE: These events will be recv'd from Playwright server with the parent
  # BrowserContext as the context/bound :guid. So, we need to add our handlers
  # there, on that (BrowserContext) parent.
  #
  # For :update_subscription, :event is one of:
  # (console|dialog|fileChooser|request|response|requestFinished|requestFailed)
  def on(%Page{session: session} = page, event, callback)
      when event in [:console, :dialog, :file_chooser, :request, :response, :request_finished, :request_failed] do
    # HACK!
    e = Atom.to_string(event) |> Recase.to_camel()

    Channel.post({page, :update_subscription}, %{event: e, enabled: true})
    Channel.bind(session, {:guid, context(page).guid}, event, callback)
  end

  def on(%Page{session: session} = page, event, callback) when is_atom(event) do
    Channel.bind(session, {:guid, page.guid}, event, callback)
  end

  # ---

  # @spec pdf(t(), options()) :: binary() # ?
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

  | key/name      | type   |            | description |
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
  def reload(%Page{} = page, options \\ %{}) do
    Channel.post({page, :reload}, options)
  end

  # ---

  # @spec remove_locator_handler(t(), Locator.t()) :: :ok
  # def remove_locator_handler(page, locator)

  # ---

  @spec request(t()) :: Playwright.APIRequestContext.t()
  def request(%Page{session: session} = page) do
    Channel.list(session, {:guid, page.owned_context.browser.guid}, "APIRequestContext")
    |> List.first()
  end

  @spec route(t(), binary(), function(), map()) :: t() | Playwright.API.Error.t()
  def route(page, pattern, handler, options \\ %{})

  def route(%Page{session: session} = page, pattern, handler, _options) do
    with_latest(page, fn page ->
      matcher = Helpers.URLMatcher.new(pattern)
      handler = Helpers.RouteHandler.new(matcher, handler)

      routes = [handler | page.routes]
      patterns = Helpers.RouteHandler.prepare(routes)

      Channel.patch(session, {:guid, page.guid}, %{routes: routes})
      Channel.post({page, :set_network_interception_patterns}, %{patterns: patterns})
    end)
  end

  # ---

  # @spec route_from_har(t(), binary(), map()) :: :ok
  # def route_from_har(page, har, options \\ %{})

  # ---

  @spec screenshot(t(), options()) :: binary()
  def screenshot(%Page{} = page, options \\ %{}) do
    case Map.pop(options, :path) do
      {nil, params} ->
        Channel.post({page, :screenshot}, params)

      {path, params} ->
        [_, filetype] = String.split(path, ".")

        data = Channel.post({page, :screenshot}, Map.put(params, :type, filetype))
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

  @spec set_content(t(), binary(), options()) :: t() | {:error, Error.t()}
  def set_content(%Page{} = page, html, options \\ %{}) do
    returning(page, fn ->
      main_frame(page) |> Frame.set_content(html, options)
    end)
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
    Channel.post({page, :set_viewport_size}, %{viewport_size: dimensions})
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
  # def unroute(page, handler \\ nil)

  # @spec unroute_all(t(), map()) :: :ok
  # def unroute_all(page, options \\ %{})

  # ---

  @spec url(t()) :: binary()
  def url(%Page{} = page) do
    main_frame(page) |> Frame.url()
  end

  # ---

  # @spec video(t()) :: Video.t() | nil
  # def video(page, handler \\ nil)

  # @spec viewport_size(t()) :: dimensions() | nil
  # def viewport_size(page)

  # @spec wait_for_event(t(), binary(), map()) :: map()
  # def wait_for_event(page, event, options \\ %{})

  # @spec wait_for_function(Page.t(), expression(), any(), options()) :: JSHandle.t()
  # def wait_for_function(page, expression, arg \\ nil, options \\ %{})

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

  # @spec wait_for_url(Page.t(), binary(), options()) :: :ok
  # def wait_for_url(page, url, options \\ %{})

  # @spec workers(t()) :: [Worker.t()]
  # def workers(page)

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

  defp on_binding(page, binding) do
    Playwright.BindingCall.call(binding, Map.get(page.bindings, binding.name))
  end

  # Do not love this.
  # It's good enough for now (to deal with v1.26.0 changes). However, it feels
  # dirty for API resource implementations to be reaching into Catalog.
  defp on_route(page, %{params: %{route: %{request: request} = route} = _params} = _event) do
    Enum.reduce_while(page.routes, [], fn handler, acc ->
      catalog = Channel.Session.catalog(page.session)
      request = Channel.Catalog.get(catalog, request.guid)

      if Helpers.RouteHandler.matches(handler, request.url) do
        Helpers.RouteHandler.handle(handler, %{request: request, route: route})
        # break
        {:halt, acc}
      else
        {:cont, [handler | acc]}
      end
    end)
  end
end
