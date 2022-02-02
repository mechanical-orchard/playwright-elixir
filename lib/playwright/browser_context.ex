# self._request: APIRequestContext = from_channel(
#   initializer["APIRequestContext"]
# )

# ---

defmodule Playwright.BrowserContext do
  @moduledoc """
  `Playwright.BrowserContext` provides a way to operate multiple independent
  browser sessions.

  If a page opens another page, e.g. with a `window.open` call, the popup will
  belong to the parent page's browser context.

  Playwright allows creation of "incognito" browser contexts with the
  `Playwright.Browser.new_context/1` function.

  ## Example

      # create a new "incognito" browser context:
      context = Playwright.Browser.new_context(browser)

      # create and use a new page within that context:
      page = Playwright.BrowserContext.new_page(context)
      resp =  = Playwright.Page.goto(page, "https://example.com")

      # dispose the context once it's no longer needed:
      Playwright.BrowserContext.close(context)

  ## Regarding `expect_event/5` and `on/3`

  The first argument given to `on/3` and `expect_event/5` functions is the
  "owner" on which to bind the event.

  The second argument is the event type.

  The third argument is a callback function that will be executed when the
  event fires, and is passed an instance of `Playwright.Channel.Event`.

  ### Details for `expect_event/5`

  Calls to `expect_event/5` are blocking. These functions take a "trigger",
  execution of which is expected to result in the event being fired.

  If the event does not fire within the timeout window, the call to
  `expect_event/5` will timeout.

  An optional "predicate" function may be provided, in which case the fired
  event will be sent to the predicate, which must return a "truthy" result
  in order for the expectation to be fulfilled.

      e = BrowserContext.expect_event(context, :close, fn ->
        Page.close(page)
      end)
      assert %BrowserContext{} = e.target

  ### Details for `on/3`

  Calls to `on/3` are non-blocking and register callbacks for the lifetime
  of the binding target.

      BrowserContext.on(context, :close, fn e ->
        assert %BrowserContext{} = e.target
      end)

  ### Event types

  The `expect_event/5` and `on/3` functions support the following event types:

    - `:background_page`

      Emitted when a new background page is created in the context. The event
      target is a `Playwright.Page`.

          ...

      > NOTE:
      >
      > - Only works with Chromium browser's persistent context.

    - `:close`

      Emitted when the `Playwright.BrowserContext` is closed. The event target
      is a `Playwright.BrowserContext`. This might happen because of any of the
      following:

        - Browser context is closed.
        - Browser application is closed or crashed.
        - `Playwright.Browser.close/1` is called.
        - `Playwright.Page.close/1` is with the "owner page" for this context.

    - `:page`

      Emitted when a new `Playwright.Page` is created within the context.
      The page may still be loading. The event target is a `Playwright.Page`.

      The event will also fire for popup pages.

      The earliest moment that a page is available is when it has navigated to
      the initial URL. For example, when opening a popup with
      `window.open('http://example.com')`, this event will fire when the
      network request to "http://example.com" is done and its response has
      started loading in the popup.

          BrowserContext.expect_event(context, :page, fn ->
            Page.click(page, "a[target=_blank]")
          end)

      > NOTE:
      >
      > - Use `Playwright.Page.wait_for_load_state/3` to wait until the page
      >   gets to a particular state (you should not need it in most cases).

    - `:request`

      Emitted when a request is issued from any pages created through this
      context. The event target is a `Playwright.Request`.

      To only listen for requests from a particular page, use
      `Playwright.Page.on/3` (for `:request`).

      In order to intercept and mutate requests, see `route/4` or
      `Playwright.Page.route/4`.

    - `:request_failed`

      Emitted when a request fails, for example by timing out. The event
      target is a `Playwright.Request`.

      To only listen for failed requests from a particular page, use
      `Playwright.Page.on/3` (for `:request_failed`).

      > NOTE:
      >
      > - HTTP error responses, such as 404 or 503, are still successful
      >   responses from HTTP standpoint. So, the request will complete with
      >   a `:request_finished` event and not with `:request_failed`.

    - `:request_finished`

      Emitted when a request finishes successfully after downloading the
      response body. The event target is a `Playwright.Request`.

      For a successful response, the sequence of events is `:request`,
      `:response` and `:request_finished`. To listen for successful requests
      from a particular page, use `Playwright.Page.on/3` (for
      `:request_finished`).

    - `:response`

      Emitted when response status and headers are received for a request.
      The event target is a `Playwright.Response`.

      For a successful response, the sequence of events is `:request`,
      `:response` and `:request_finished`. To listen for response events
      from a particular page, use `Playwright.Page.on/3` (for  `:response`).

    - `:service_worker`

      Emitted when new service worker is created in the context. The event
      target is a `Playwright.Worker`.

      > NOTE:
      >
      > - Service workers are only supported on Chromium-based browsers.
  """

  use Playwright.ChannelOwner
  alias Playwright.{BrowserContext, ChannelOwner, Frame, Page}
  alias Playwright.{Channel, Helpers}

  @property :bindings
  @property :browser
  @property :owner_page
  @property :routes

  @typedoc "Recognized cookie fields"
  @type cookie :: %{
          name: String.t(),
          value: String.t(),
          url: String.t(),
          domain: String.t(),
          path: String.t(),
          expires: float,
          httpOnly: boolean,
          secure: boolean,
          sameSite: String.t()
        }

  @typedoc "Supported events"
  @type event ::
          :background_page
          | :close
          | :page
          | :request
          | :request_failed
          | :request_finished
          | :response
          | :service_worker

  @typedoc "An optional (maybe nil) function or option"
  @type function_or_options :: fun() | options() | nil

  @typedoc "A map/struct providing call options"
  @type options :: map()

  @typedoc "A string URL"
  @type url :: String.t()

  # Callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%BrowserContext{session: session} = context, _initializer) do
    Channel.bind(session, {:guid, context.guid}, :binding_call, fn %{params: %{binding: binding}, target: target} ->
      on_binding(target, binding)
    end)

    Channel.bind(session, {:guid, context.guid}, :route, fn %{target: target} = e ->
      on_route(target, e)
      # NOTE: will patch here
    end)

    {:ok, %{context | bindings: %{}, browser: context.parent, routes: []}}
  end

  # API
  # ---------------------------------------------------------------------------

  @doc """
  Adds cookies into this `Playwright.BrowserContext`.

  All pages within this context will have these cookies installed. Cookies can
  be obtained via `Playwright.BrowserContext.cookies/1`.

  ## Returns

    - `:ok`

  ## Example

      :ok = BrowserContext.add_cookies(context, [cookie_1, cookie_2])

  ## Cookie fields

  | key         | type        | description |
  | ----------  | ----------- | ----------- |
  | `:name`     | `binary()`  | |
  | `:value`    | `binary()`  | |
  | `:url`      | `binary()`  | *(optional)* either url or domain / path are required |
  | `:domain`   | `binary()`  | *(optional)* either url or domain / path are required |
  | `:path`     | `binary()`  | *(optional)* either url or domain / path are required |
  | `:expires`  | `float()`   | *(optional)* Unix time in seconds. |
  | `:httpOnly` | `boolean()` | *(optional)* |
  | `:secure`   | `boolean()` | *(optional)* |
  | `:sameSite` | `binary()`  | *(optional)* one of "Strict", "Lax", "None" |
  """
  @spec add_cookies(t(), [cookie]) :: :ok
  def add_cookies(context, cookies)

  def add_cookies(%BrowserContext{session: session} = context, cookies) do
    Channel.post(session, {:guid, context.guid}, :add_cookies, %{cookies: cookies})
  end

  @doc """
  Adds a script to be evaluated before other scripts.

  The script is evaluated in the following scenarios:

  - Whenever a page is created in the browser context or is navigated.
  - Whenever a child frame is attached or navigated in any page in the browser
    context. In this case, the script is evaluated in the context of the newly
    attached frame.

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

      BrowserContext.add_init_script(context, %{path: "preload.js"})

  ## Notes

  > While the official Node.js Playwright implementation supports an optional
  > `param: arg` for this function, the official Python implementation does
  > not. This implementation matches the Python for now.

  > The order of evaluation of multiple scripts installed via
  > `Playwright.BrowserContext.add_init_script/2` and
  > `Playwright.Page.add_init_script/2` is not defined.
  """
  @spec add_init_script(t(), binary() | map()) :: :ok
  def add_init_script(%BrowserContext{session: session} = context, script) when is_binary(script) do
    params = %{source: script}
    Channel.post(session, {:guid, context.guid}, :add_init_script, params)
  end

  def add_init_script(%BrowserContext{} = context, %{path: path} = script) when is_map(script) do
    add_init_script(context, File.read!(path))
  end

  # ---

  # @spec background_pages(t()) :: [Playwright.Page.t()]
  # def background_pages(context)

  # ---

  @doc """
  Clears `Playwright.BrowserContext` cookies.
  """
  @spec clear_cookies(t()) :: :ok
  def clear_cookies(%BrowserContext{session: session} = context) do
    Channel.post(session, {:guid, context.guid}, :clear_cookies)
  end

  @spec clear_permissions(t()) :: :ok
  def clear_permissions(%BrowserContext{session: session} = context) do
    Channel.post(session, {:guid, context.guid}, :clear_permissions)
  end

  @doc """
  Closes the `Playwright.BrowserContext`. All pages that belong to the
  `Playwright.BrowserContext` will be closed.

  > NOTE:
  > - The default browser context cannot be closed.
  """
  @spec close(t()) :: :ok
  def close(%BrowserContext{session: session} = context) do
    case Channel.post(session, {:guid, context.guid}, :close) do
      :ok ->
        :ok

      {:error, %Channel.Error{message: "Target page, context or browser has been closed"}} ->
        :ok
    end
  end

  @doc """
  Returns cookies for the `Playwright.BrowserContext`.

  If no URLs are specified, this method returns all cookies. If URLs are
  specified, only cookies that affect those URLs are returned.

  ## Returns

    - `[cookie()]` See `add_cookies/2` for cookie field details.

  ## Arguments

  | key/name | type  |                            | description |
  | ---------- | ----- | -------------------------- | ----------- |
  | `urls`     | param | `binary()` or `[binary()]` | List of URLs. `(optional)` |
  """
  @spec cookies(t(), url | [url]) :: [cookie]
  def cookies(%BrowserContext{session: session} = context, urls \\ []) do
    Channel.post(session, {:guid, context.guid}, :cookies, %{urls: urls})
  end

  @doc """
  Waits for an event to fire (i.e., is blocking) and passes its value into the
  predicate function.

  Returns when the predicate returns a truthy value. Throws an error if the
  context closes before the event is fired. Returns a `Playwright.Channel.Event`.

  ## Arguments

  - `event`: Event name; the same as those passed to `Playwright.BrowserContext.on/3`
  - `predicate`: Receives the `Playwright.Channel.Event` and resolves to a
    "truthy" value when the waiting should resolve.
  - `options`:
    - `predicate`: ...
    - `timeout`: The maximum time to wait in milliseconds. Defaults to 30000
      (30 seconds). Pass 0 to disable timeout. The default value can be changed
      via `Playwright.BrowserContext.set_default_timeout/2`.

  ## Example

      event_info = BrowserContext.expect_event(context, :page, fn ->
        BrowserContext.new_page(context)
      end)
  """
  def expect_event(context, event, options \\ %{}, trigger \\ nil)

  def expect_event(%BrowserContext{session: session} = context, event, options, trigger) do
    Channel.wait(session, {:guid, context.guid}, event, options, trigger)
  end

  @doc """
  Executes `trigger` and waits for a new `Playwright.Page` to be created within
  the `Playwright.BrowserContext`.

  If `predicate` is provided, it passes the `Playwright.Page` value into the
  predicate function, wrapped in `Playwright.Channel.Event`, and waits for
  `predicate/1` to return a "truthy" value. Throws an error if the context
  closes before new `Playwright.Page` is created.

  ## Arguments

  - `predicate`: Receives the `Playwright.Page` and resolves to truthy value
    when the waiting should resolve.
  - `options`:
    - `predicate`: ...
    - `timeout`: The maximum time to wait in milliseconds. Defaults to 30000
      (30 seconds). Pass 0 to disable timeout. The default value can be changed
      via `Playwright.BrowserContext.set_default_timeout/2`.
  """
  # Temporarily disable spec:
  # @spec expect_page(t(), map(), function()) :: Playwright.Channel.Event.t()
  def expect_page(context, options \\ %{}, trigger \\ nil) do
    expect_event(context, :page, options, trigger)
  end

  @doc """
  Adds a function called `param: name` on the `window` object of every
  frame in every page in the context.
  """
  @spec expose_binding(t(), String.t(), function(), options()) :: :ok
  def expose_binding(%BrowserContext{session: session} = context, name, callback, options \\ %{}) do
    bindings = context.bindings
    Channel.patch(session, {:guid, context.guid}, %{bindings: Map.merge(bindings, %{name => callback})})

    params = Map.merge(%{name: name, needs_handle: false}, options)
    Channel.post(session, {:guid, context.guid}, :expose_binding, params)
  end

  @spec expose_function(t(), String.t(), function()) :: :ok
  def expose_function(context, name, callback) do
    expose_binding(context, name, fn _, args ->
      callback.(args)
    end)
  end

  @spec grant_permissions(t(), [String.t()], options()) :: :ok | {:error, Channel.Error.t()}
  def grant_permissions(%BrowserContext{session: session} = context, permissions, options \\ %{}) do
    params = Map.merge(%{permissions: permissions}, options)
    Channel.post(session, {:guid, context.guid}, :grant_permissions, params)
  end

  @spec new_cdp_session(t(), Frame.t() | Page.t()) :: Playwright.CDPSession.t()
  def new_cdp_session(context, owner)

  def new_cdp_session(%BrowserContext{session: session} = context, %Frame{} = frame) do
    Channel.post(session, {:guid, context.guid}, "newCDPSession", %{frame: %{guid: frame.guid}})
  end

  def new_cdp_session(%BrowserContext{session: session} = context, %Page{} = page) do
    Channel.post(session, {:guid, context.guid}, "newCDPSession", %{page: %{guid: page.guid}})
  end

  @doc """
  Creates a new `Playwright.Page` in the context.

  If the context is already "owned" by a `Playwright.Page` (i.e., was created
  as a side effect of `Playwright.Browser.new_page/1`), will raise an error
  because there should be a 1-to-1 mapping in that case.
  """
  @spec new_page(t()) :: Page.t()
  def new_page(context)

  def new_page(%BrowserContext{session: session} = context) do
    case context.owner_page do
      nil ->
        Channel.post(session, {:guid, context.guid}, :new_page)

      %Playwright.Page{} ->
        raise(RuntimeError, message: "Please use Playwright.Browser.new_context/1")
    end
  end

  @doc """
  Register a (non-blocking) callback/handler for various types of events.
  """
  @spec on(t(), event(), function()) :: :ok
  def on(%BrowserContext{session: session} = context, event, callback) do
    Channel.bind(session, {:guid, context.guid}, event, callback)
  end

  @doc """
  Returns all open pages in the context.

  ## Returns

    - `[Page.t()]`
  """
  @spec pages(t()) :: [Page.t()]
  def pages(%BrowserContext{} = context) do
    Channel.list(context.session, {:guid, context.guid}, "Page")
  end

  @spec route(t(), binary(), function(), map()) :: :ok
  def route(context, pattern, handler, options \\ %{})

  def route(%BrowserContext{session: session} = context, pattern, handler, _options) do
    with_latest(context, fn context ->
      matcher = Helpers.URLMatcher.new(pattern)
      handler = Helpers.RouteHandler.new(matcher, handler)
      routes = context.routes

      if Enum.empty?(routes) do
        Channel.post(session, {:guid, context.guid}, :set_network_interception_enabled, %{enabled: true})
      end

      Channel.patch(session, {:guid, context.guid}, %{routes: [handler | routes]})
      :ok
    end)
  end

  # ---

  # ???
  # @spec service_workers(t()) :: [Playwright.Worker.t()]
  # def service_workers(context)

  # test_navigation.py
  # @spec set_default_navigation_timeout(t(), number()) :: :ok
  # def set_default_navigation_timeout(context, timeout)

  # test_navigation.py
  # @spec set_default_timeout(t(), number()) :: :ok
  # def set_default_timeout(context, timeout)

  # test_interception.py
  # test_network.py
  # @spec set_extra_http_headers(t(), headers()) :: :ok
  # def set_extra_http_headers(context, headers)

  # test_geolocation.py
  # @spec set_geolocation(t(), geolocation()) :: :ok
  # def set_geolocation(context, geolocation)

  # ???
  # @spec set_http_credentials(t(), http_credentials()) :: :ok
  # def set_http_credentials(context, http_credentials)

  # ---

  @spec set_offline(t(), boolean()) :: :ok
  def set_offline(%BrowserContext{session: session} = context, offline) do
    Channel.post(session, {:guid, context.guid}, :set_offline, %{offline: offline})
  end

  # ---

  # @spec storage_state(t(), String.t()) :: {:ok, storage_state()}
  # def storage_state(context, path \\ nil)

  # ---

  @spec unroute(t(), binary(), function() | nil) :: :ok
  def unroute(%BrowserContext{session: session} = context, pattern, callback \\ nil) do
    with_latest(context, fn context ->
      remaining =
        Enum.filter(context.routes, fn handler ->
          handler.matcher.match != pattern || (callback && handler.callback != callback)
        end)

      Channel.patch(session, {:guid, context.guid}, %{routes: remaining})
      :ok
    end)
  end

  # private
  # ---------------------------------------------------------------------------

  defp on_binding(context, binding) do
    Playwright.BindingCall.call(binding, Map.get(context.bindings, binding.name))
  end

  # NOTE:
  # Still need to remove the handler when it does the job. Like the following:
  #
  #     if handler_entry.matches(request.url):
  #         if handler_entry.handle(route, request):
  #             self._routes.remove(handler_entry)
  #             if not len(self._routes) == 0:
  #                 asyncio.create_task(self._disable_interception())
  #         break
  #
  # ...hoping for a test to drive that out.
  defp on_route(context, %{params: %{request: request} = params} = _event) do
    Enum.reduce_while(context.routes, [], fn handler, acc ->
      if Helpers.RouteHandler.matches(handler, request.url) do
        Helpers.RouteHandler.handle(handler, params)
        # break
        {:halt, acc}
      else
        {:cont, [handler | acc]}
      end
    end)
  end
end
