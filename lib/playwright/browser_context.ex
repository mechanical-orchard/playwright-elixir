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
  event fires, and is passed an event struct containing the event details.

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

  use Playwright.SDK.ChannelOwner
  alias Playwright.{BrowserContext, Frame, Page, Worker}
  alias Playwright.SDK.{Channel, ChannelOwner, Helpers}

  @property :bindings
  @property :browser
  @property :owner_page
  @property :routes
  @property :tracing
  @property :websocket_routes

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
          sameSite: String.t(),
          partitionKey: String.t()
        }

  @typedoc "Supported events"
  @type event ::
          :close
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

    Channel.bind(session, {:guid, context.guid}, :web_socket_route, fn %{params: params, target: target} ->
      on_web_socket_route(target, params)
      :ok
    end)

    {:ok, %{context | bindings: %{}, browser: context.parent, routes: [], websocket_routes: []}}
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

    case Channel.post(session, {:guid, context.guid}, :add_init_script, params) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
      %{guid: _} -> :ok
    end
  end

  def add_init_script(%BrowserContext{} = context, %{path: path} = script) when is_map(script) do
    add_init_script(context, File.read!(path))
  end

  # ---

  @doc """
  Returns all background pages in the context.

  This only works with Chromium persistent contexts.

  ## Returns

  - `[Page.t()]`
  """
  @doc deprecated: "backgroundPage event was removed in Playwright 1.57"
  @spec background_pages(t()) :: [Page.t()]
  def background_pages(%BrowserContext{}) do
    []
  end

  # @spec browser(t()) :: Playwright.Browser.t()
  # def browser(context)

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
    # A call to `close` will remove the item from the catalog. `Catalog.find`
    # here ensures that we do not `post` a 2nd `close`.
    case Channel.find(session, {:guid, context.guid}, %{timeout: 10}) do
      %BrowserContext{} ->
        Channel.post(session, {:guid, context.guid}, :close)
        :ok

      {:error, _} ->
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
  context closes before the event is fired. Returns a channel event struct.

  ## Arguments

  - `event`: Event name; the same as those passed to `Playwright.BrowserContext.on/3`
  - `predicate`: Receives the channel event and resolves to a
    "truthy" value when the waiting should resolve.
  - `options`:
    - `predicate`: ...
    - `timeout`: The maximum time to wait in milliseconds. Defaults to 30000
      (30 seconds). Pass 0 to disable timeout. The default value can be changed
      via BrowserContext timeout settings.

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
  predicate function, wrapped in a channel event struct, and waits for
  `predicate/1` to return a "truthy" value. Throws an error if the context
  closes before new `Playwright.Page` is created.

  ## Arguments

  - `predicate`: Receives the `Playwright.Page` and resolves to truthy value
    when the waiting should resolve.
  - `options`:
    - `predicate`: ...
    - `timeout`: The maximum time to wait in milliseconds. Defaults to 30000
      (30 seconds). Pass 0 to disable timeout. The default value can be changed
      via BrowserContext timeout settings.
  """
  # Temporarily disable spec (channel event type is internal)
  def expect_page(context, options \\ %{}, trigger \\ nil) do
    expect_event(context, :page, options, trigger)
  end

  @doc """
  Adds a function called `param:name` on the `window` object of every frame in
  every page in the context.

  When called, the function executes `param:callback` and resolves to the return
  value of the `callback`.

  The first argument to the `callback` function includes the following details
  about the caller:

      %{
        context: %Playwright.BrowserContext{},
        frame:   %Playwright.Frame{},
        page:    %Playwright.Page{}
      }

  See `Playwright.Page.expose_binding/4` for a similar, page-scoped version.
  """
  @spec expose_binding(BrowserContext.t(), String.t(), function(), options()) :: BrowserContext.t()
  def expose_binding(%BrowserContext{session: session} = context, name, callback, options \\ %{}) do
    Channel.patch(session, {:guid, context.guid}, %{bindings: Map.merge(context.bindings, %{name => callback})})
    post!(context, :expose_binding, Map.merge(%{name: name, needs_handle: false}, options))
  end

  @doc """
  Adds a function called `param:name` on the `window` object of every frame in
  every page in the context.

  When called, the function executes `param:callback` and resolves to the return
  value of the `callback`.

  See `Playwright.Page.expose_function/3` for a similar, Page-scoped version.
  """
  @spec expose_function(BrowserContext.t(), String.t(), function()) :: BrowserContext.t()
  def expose_function(context, name, callback) do
    expose_binding(context, name, fn _, args ->
      callback.(args)
    end)
  end

  @spec grant_permissions(t(), [String.t()], options()) :: :ok | {:error, term()}
  def grant_permissions(%BrowserContext{session: session} = context, permissions, options \\ %{}) do
    params = Map.merge(%{permissions: permissions}, options)
    Channel.post(session, {:guid, context.guid}, :grant_permissions, params)
  end

  @spec new_cdp_session(t(), Frame.t() | Page.t()) :: struct()
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

  @spec route(t(), binary() | Regex.t(), function(), map()) :: t() | {:error, term()}
  def route(context, pattern, handler, options \\ %{})

  def route(%BrowserContext{session: session} = context, pattern, handler, _options) do
    with_latest(context, fn context ->
      matcher = Helpers.URLMatcher.new(pattern)
      handler = Helpers.RouteHandler.new(matcher, handler)

      routes = [handler | context.routes]
      patterns = Helpers.RouteHandler.prepare(routes)

      Channel.patch(session, {:guid, context.guid}, %{routes: routes})
      Channel.post(session, {:guid, context.guid}, :set_network_interception_patterns, %{patterns: patterns})
    end)
  end

  # ---

  # @spec route_from_har(t(), binary(), map()) :: :ok
  # def route(context, har, options \\ %{})

  @doc """
  Routes WebSocket connections matching the URL pattern to the handler.

  This applies to all pages within the context.

  ## Example

      BrowserContext.route_web_socket(context, "**/ws", fn ws ->
        server = WebSocketRoute.connect_to_server(ws)

        WebSocketRoute.on_message(ws, fn msg ->
          IO.puts("Page -> Server: \#{msg}")
          WebSocketRoute.Server.send(server, msg)
        end)

        WebSocketRoute.Server.on_message(server, fn msg ->
          IO.puts("Server -> Page: \#{msg}")
          WebSocketRoute.send(ws, msg)
        end)
      end)
  """
  @spec route_web_socket(t(), binary() | Regex.t(), (Playwright.WebSocketRoute.t() -> any())) ::
          t() | {:error, term()}
  def route_web_socket(%BrowserContext{session: session} = context, pattern, handler)
      when is_function(handler, 1) do
    with_latest(context, fn context ->
      matcher = Helpers.URLMatcher.new(pattern)
      ws_handler = Helpers.WebSocketRouteHandler.new(matcher, handler)

      websocket_routes = [ws_handler | context.websocket_routes]
      patterns = Helpers.WebSocketRouteHandler.prepare(websocket_routes)

      Channel.patch(session, {:guid, context.guid}, %{websocket_routes: websocket_routes})
      Channel.post(session, {:guid, context.guid}, :set_web_socket_interception_patterns, %{patterns: patterns})
    end)
  end

  @doc """
  Returns all service workers in the context.

  ## Returns

  - `[Worker.t()]`

  ## Note

  Currently returns an empty list. Full tracking of service workers
  via events is a future enhancement.
  """
  @spec service_workers(t()) :: [Worker.t()]
  def service_workers(%BrowserContext{}) do
    []
  end

  @doc """
  Sets the default timeout for all context operations.

  This setting will change the default maximum time for all the methods
  accepting a `timeout` option.

  ## Arguments

  | key/name  | type       | description                      |
  | --------- | ---------- | -------------------------------- |
  | `timeout` | `number()` | Maximum time in milliseconds.    |

  ## Returns

  - `:ok`

  ## Example

      BrowserContext.set_default_timeout(context, 60_000)  # 60 seconds
  """
  @spec set_default_timeout(t(), number()) :: :ok
  def set_default_timeout(%BrowserContext{session: session, guid: guid}, timeout) do
    Channel.post(session, {:guid, guid}, :set_default_timeout_no_reply, %{timeout: timeout})
    :ok
  end

  @doc """
  Sets the default timeout for navigation operations.

  This setting will change the default maximum navigation time for the
  following methods and related shortcuts on page: `goto`, `go_back`,
  `go_forward`, `reload`, `wait_for_navigation`.

  ## Arguments

  | key/name  | type       | description                      |
  | --------- | ---------- | -------------------------------- |
  | `timeout` | `number()` | Maximum time in milliseconds.    |

  ## Returns

  - `:ok`

  ## Example

      BrowserContext.set_default_navigation_timeout(context, 90_000)  # 90 seconds
  """
  @spec set_default_navigation_timeout(t(), number()) :: :ok
  def set_default_navigation_timeout(%BrowserContext{session: session, guid: guid}, timeout) do
    Channel.post(session, {:guid, guid}, :set_default_navigation_timeout_no_reply, %{timeout: timeout})
    :ok
  end

  @doc """
  Sets extra HTTP headers to be sent with every request.

  These headers will be sent with every request initiated by any page in
  the context. Headers set with `Page.set_extra_http_headers/2` take
  precedence over headers set with this method.

  ## Arguments

  | key/name  | type     | description                                |
  | --------- | -------- | ------------------------------------------ |
  | `headers` | `map()`  | Map of header names to values.             |

  ## Returns

  - `:ok`

  ## Example

      BrowserContext.set_extra_http_headers(context, %{
        "Authorization" => "Bearer token123",
        "X-Custom-Header" => "value"
      })
  """
  @spec set_extra_http_headers(t(), map()) :: :ok
  def set_extra_http_headers(%BrowserContext{session: session, guid: guid}, headers) when is_map(headers) do
    header_list = Enum.map(headers, fn {name, value} -> %{name: to_string(name), value: value} end)
    Channel.post(session, {:guid, guid}, :set_extra_http_headers, %{headers: header_list})
    :ok
  end

  @doc """
  Sets the geolocation for this browser context.

  All pages in this context will use the overridden geolocation.

  ## Parameters

  - `geolocation` - A map with `:latitude`, `:longitude`, and optional `:accuracy`.
    - `:latitude` - Latitude between -90 and 90
    - `:longitude` - Longitude between -180 and 180
    - `:accuracy` - Non-negative accuracy in meters (default: 0)

  ## Examples

      # Set geolocation to San Francisco
      BrowserContext.set_geolocation(context, %{latitude: 37.7749, longitude: -122.4194})

      # With accuracy
      BrowserContext.set_geolocation(context, %{latitude: 37.7749, longitude: -122.4194, accuracy: 100})

  ## Note

  Consider also granting the 'geolocation' permission:

      BrowserContext.grant_permissions(context, ["geolocation"])
  """
  @spec set_geolocation(t(), map()) :: :ok
  def set_geolocation(%BrowserContext{session: session} = context, geolocation) do
    Channel.post(session, {:guid, context.guid}, :set_geolocation, %{geolocation: geolocation})
  end

  @doc """
  Sets HTTP authentication credentials for requests.

  Pass `nil` to disable authentication.

  ## Arguments

  | key/name      | type                                               | description                     |
  | ------------- | -------------------------------------------------- | ------------------------------- |
  | `credentials` | `%{username: binary(), password: binary()} \| nil` | Credentials or nil to disable.  |

  ## Returns

  - `:ok`

  ## Example

      BrowserContext.set_http_credentials(context, %{username: "user", password: "pass"})
      # Later, to disable:
      BrowserContext.set_http_credentials(context, nil)
  """
  @spec set_http_credentials(t(), %{username: binary(), password: binary()} | nil) :: :ok
  def set_http_credentials(%BrowserContext{session: session, guid: guid}, credentials) do
    params = %{httpCredentials: credentials}
    Channel.post(session, {:guid, guid}, :set_http_credentials, params)
    :ok
  end

  # ---

  @spec set_offline(t(), boolean()) :: :ok
  def set_offline(%BrowserContext{session: session} = context, offline) do
    Channel.post(session, {:guid, context.guid}, :set_offline, %{offline: offline})
  end

  # ---

  @doc """
  Returns storage state for this browser context, contains current cookies and local storage snapshot.

  ## Options

  - `:path` - Optional path to save the storage state as JSON file.

  ## Examples

      # Get storage state as map
      state = BrowserContext.storage_state(context)

      # Save to file
      state = BrowserContext.storage_state(context, path: "/tmp/auth.json")

  ## Returns

  A map with `:cookies` and `:origins` keys.
  """
  @spec storage_state(t(), keyword()) :: map() | {:error, term()}
  def storage_state(%BrowserContext{session: session} = context, options \\ []) do
    params =
      case Keyword.get(options, :indexed_db) do
        nil -> %{}
        val -> %{indexedDB: val}
      end

    case Channel.post(session, {:guid, context.guid}, :storage_state, params) do
      {:error, _} = error ->
        error

      state when is_map(state) ->
        case Keyword.get(options, :path) do
          nil ->
            state

          path ->
            json = Jason.encode!(state, pretty: true)
            File.write!(path, json)
            state
        end
    end
  end

  # ---

  @spec unroute(t(), binary() | Regex.t(), function() | nil) :: t() | {:error, term()}
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

  @doc """
  Removes all routes registered with `route/4`.

  ## Options

  | key/name   | type       | description                                      |
  | ---------- | ---------- | ------------------------------------------------ |
  | `:behavior`| `binary()` | How to handle in-flight requests. One of:        |
  |            |            | `"default"` - abort in-flight requests           |
  |            |            | `"wait"` - wait for in-flight handlers           |
  |            |            | `"ignoreErrors"` - ignore handler errors         |

  ## Returns

  - `:ok`

  ## Example

      # Add a route
      BrowserContext.route(context, "**/*", fn route -> Route.abort(route) end)

      # Later, remove all routes
      BrowserContext.unroute_all(context)

      # Or wait for in-flight handlers to complete
      BrowserContext.unroute_all(context, %{behavior: "wait"})
  """
  @spec unroute_all(t(), map()) :: :ok
  def unroute_all(%BrowserContext{session: session, guid: guid}, options \\ %{}) do
    params = if options[:behavior], do: %{behavior: options[:behavior]}, else: %{}
    Channel.post(session, {:guid, guid}, :unroute_all, params)
    Channel.patch(session, {:guid, guid}, %{routes: []})
    Channel.post(session, {:guid, guid}, :set_network_interception_patterns, %{patterns: []})
    :ok
  end

  # @spec wait_for_event(t(), binary(), map()) :: map()
  # def wait_for_event(context, event, options \\ %{})

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

  # NOTE(20240525):
  # Do not love this; See Page.on_route/2 (which is an exact copy of this) for why.
  defp on_route(context, %{params: %{route: %{request: request} = route} = _params} = _event) do
    Enum.reduce_while(context.routes, [], fn handler, acc ->
      catalog = Channel.Session.catalog(context.session)
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

  defp on_web_socket_route(context, %{webSocketRoute: ws_route}) do
    # ws_route is already hydrated by Event.new
    handle_web_socket_route(context, ws_route)
  end

  @doc false
  # Called by Page when it has no matching handler
  def handle_web_socket_route(context, ws_route) do
    handler =
      Enum.find(context.websocket_routes, fn h ->
        Helpers.WebSocketRouteHandler.matches(h, ws_route.url)
      end)

    if handler do
      Helpers.WebSocketRouteHandler.handle(handler, ws_route)
    else
      # No handler, connect through
      Playwright.WebSocketRoute.connect_to_server(ws_route)
    end
  end
end
