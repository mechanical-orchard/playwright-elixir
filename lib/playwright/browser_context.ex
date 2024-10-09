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
  event fires, and is passed an instance of `Playwright.SDK.Channel.Event`.

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

  use Playwright.SDK.ChannelOwner
  alias Playwright.{BrowserContext, Frame, Page}
  alias Playwright.API.Error
  alias Playwright.SDK.{Channel, ChannelOwner, Helpers}

  @property :bindings
  @property :browser
  @property :owner_page
  @property :routes

  @typedoc "An HTTP cookie."
  @type cookie :: %{
          optional(:name) => String.t(),
          optional(:value) => String.t(),
          required(:domain) => String.t(),
          required(:path) => String.t(),
          optional(:expires) => float(),
          optional(:http_only) => boolean(),
          optional(:secure) => boolean(),
          # same_site: "Lax" | "None" | "Strict"
          optional(:same_site) => String.t()
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

  @typedoc "Geolocation emulation settings."
  @type geolocation :: %{
          required(:latitude) => number(),
          required(:longitude) => number(),
          optional(:accuracy) => number()
        }

  @typedoc "A map/struct providing generic call options"
  @type options :: map()

  @typedoc "Options for calls to `clear_cookies/2`"
  @type opts_clear_cookies :: %{
          optional(:domain) => String.t() | Regex.t(),
          optional(:name) => String.t() | Regex.t(),
          optional(:path) => String.t() | Regex.t()
        }

  @typedoc "Options for `close/2`."
  @type opts_close :: %{
          optional(:reason) => String.t()
        }

  @typedoc "Options for `grant_permissions/3`."
  @type opts_permissions :: %{
          optional(:origin) => String.t()
        }

  @typedoc "Options for `route/4`"
  @type opts_route :: %{
          optional(:times) => number()
        }

  @typedoc "A permission available for `grant_permissions/3`."
  @type permission :: String.t() | atom()

  @typedoc "A route matcher for `route/4"
  @type route_url :: String.t() | Regex.t() | function()

  @typedoc "JavaScript provided as a filesystem path, or as script content."
  @type script ::
          %{
            optional(:content) => String.t(),
            optional(:path) => String.t()
          }
          | function()
          | String.t()

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

  ## Usage

      BrowserContext.add_cookies(context, [cookie_1, cookie_2])

  ## Cookie settings

  | name         |             | description |
  | ------------ | ----------- | ----------- |
  | `:name`      | optional()  |             |
  | `:value`     | optional()  |             |
  | `:url`       | optional()  | One of `:url` or `:domain` / `:path` are required. |
  | `:domain`    | optional()  | One of `:url` or `:domain` / `:path` are required. For the cookie to apply to all subdomains as well, prefix `:domain` with a dot, like so: `".example.com"`. |
  | `:path`      | optional()  | One of `:url` or `:domain` / `:path` are required. |
  | `:expires`   | optional()  | Unix time in seconds. |
  | `:http_only` | optional()` |             |
  | `:secure`    | optional()` |             |
  | `:same_site` | optional()  | One of "Strict", "Lax", "None" |

  ## Returns

    - `Playwright.BrowserContext.t()`
    - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:add_cookies, [:context, :cookies]}
  @spec add_cookies(t(), [cookie]) :: t() | {:error, Error.t()}
  def add_cookies(context, cookies)

  def add_cookies(%BrowserContext{} = context, cookies) do
    Channel.post({context, :add_cookies}, %{cookies: cookies})
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

  ## Usage

  Overriding `Math.random` before the page loads:

      # preload.js
      Math.random = () => 42;

      # Playwright script
      BrowserContext.add_init_script(context, %{path: "preload.js"})

  > #### NOTE {: .info}
  >
  > The order of evaluation of multiple scripts installed via
  > `Playwright.BrowserContext.add_init_script/2` and
  > `Playwright.Page.add_init_script/2` is not defined.

  ## Arguments

  | name        |            | description |
  | ----------- | ---------- | ----------- |
  | `script`    |            | `script()`  |
  | `arg`       | (optional) | An optional argument to be passed to the `:script` (only supported when `:script` is a `function()`). |

  ### Script details

  The `:script` argument may be provided as follows:

  - As `function()`, is an Elixir callback. This mechanism supports an optional
    `:arg` to be passed to the script at evaluation.
  - As a `String.t()`, is raw script content to be evaluated.
  - As a `map()`, one of the following:
    - `:content` - Raw script content to be evaluated.
    - `:path` - A path to a JavaScript file. If `:path` is a relative path, it
      is resolved to the current working directory.

  ## Returns

    - `Playwright.BrowserContext.t()`
    - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:add_init_script, [:context, :script]}
  @spec add_init_script(t(), script()) :: t() | {:error, Error.t()}
  def add_init_script(%BrowserContext{} = context, script) when is_binary(script) do
    Channel.post({context, :add_init_script}, %{source: script})
  end

  def add_init_script(%BrowserContext{} = context, %{path: path} = script) when is_map(script) do
    add_init_script(context, File.read!(path))
  end

  # @spec background_pages(t()) :: [Playwright.Page.t()]
  # def background_pages(%BrowserContext{} = context)

  @doc """
  Clears `Playwright.BrowserContext` cookies. Accepts an optional filter.

  ## Usage

      BrowserContext.clear_cookies(context)
      BrowserContext.clear_cookies(context, %{name: "session-id"})
      BrowserContext.clear_cookies(context, %{domain: "example.com"})
      BrowserContext.clear_cookies(context, %{domain: ~r/.*example\.com/})
      BrowserContext.clear_cookies(context, %{path: "/api/v1"})
      BrowserContext.clear_cookies(context, %{name: "session-id", domain: "example.com"})

  ## Arguments

  | name             |            | description                       |
  | ---------------- | ---------- | --------------------------------- |
  | `context`        |            | The "subject" `BrowserContext`    |
  | `options`        | (optional) | Options (see below)               |

  ### Options

  | name     |            | description                       |
  | -------- | ---------- | --------------------------------- |
  | `domain` | (optional) | Filters to only remove cookies with the given domain. |
  | `name`   | (optional) | Filters to only remove cookies with the given name. |
  | `path`   | (optional) | Filters to only remove cookies with the given path. |

  ## Returns

  - `Playwright.BrowserContext.t()`
  - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:clear_cookies, [:context]}
  @pipe {:clear_cookies, [:context, :options]}
  @spec clear_cookies(t(), opts_clear_cookies()) :: t() | {:error, Error.t()}
  def clear_cookies(context, options \\ %{})

  def clear_cookies(%BrowserContext{} = context, options) do
    Channel.post({context, :clear_cookies}, options)
  end

  @doc """
  Clears all permission overrides for the `Playwright.BrowserContext`.

  ## Usage

      BrowserContext.grant_permissions(context, ["clipboard-read"])
      BrowserContext.clear_permissions(context)

  ## Arguments

  | name             |            | description                       |
  | ---------------- | ---------- | --------------------------------- |
  | `context`        |            | The "subject" `BrowserContext`    |

  ## Returns

  - `Playwright.BrowserContext.t()`
  - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:clear_permissions, [:context]}
  @spec clear_permissions(t()) :: t() | {:error, Error.t()}
  def clear_permissions(%BrowserContext{} = context) do
    Channel.post({context, :clear_permissions})
  end

  @doc """
  Closes the `Playwright.BrowserContext`. All pages that belong to the
  context will be closed.

  > #### NOTE {: .info}
  >
  > The default browser context cannot be closed.

  ## Usage

      BrowserContext.close(context)
      BrowserContext.close(context, %{reason: "All done"})

  ## Arguments

  | name             |            | description                       |
  | ---------------- | ---------- | --------------------------------- |
  | `context`        |            | The "subject" `BrowserContext`    |
  | `options`        | (optional) | Options (see below)               |

  ### Options

  | name     |            | description                       |
  | -------- | ---------- | --------------------------------- |
  | `reason` | (optional) | The reason to be reported to any operations interrupted by the context disposal. |

  ## Returns

  - `:ok`
  """
  @spec close(t(), opts_close()) :: :ok
  def close(%BrowserContext{} = context, options \\ %{}) do
    # A call to `close` will remove the item from the catalog. `Catalog.find`
    # here ensures that we do not `post` a 2nd `close`.
    case Channel.find(context.session, {:guid, context.guid}, %{timeout: 10}) do
      %BrowserContext{} ->
        Channel.close(context, options)

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Returns cookies for the `Playwright.BrowserContext`.

  If no URLs are specified, this method returns all cookies. If URLs are
  specified, only cookies that affect those URLs are returned.

  ## Usage

      BrowserContext.cookies(context)
      BrowserContext.cookies(context, "https://example.com")
      BrowserContext.cookies(context, ["https://example.com"])

  ## Arguments

  | name       |            | description                     |
  | ---------- | ---------- | ------------------------------- |
  | `context`  |            | The "subject" `BrowserContext`. |
  | `urls`     | (optional) | A list of URLs.                 |

  ## Returns

  - `[cookie()]` See `add_cookies/2` for cookie field details.
  - `{:error, Playwright.API.Error.t()}`
  """
  @spec cookies(t(), url() | [url()]) :: [cookie()] | {:error, Error.t()}
  def cookies(%BrowserContext{} = context, urls \\ []) do
    Channel.post({context, :cookies}, %{urls: urls})
  end

  @doc """
  Waits for an event to fire (i.e., is blocking) and passes its value into the
  predicate function.

  Returns when the predicate returns a truthy value. Throws an error if the
  context closes before the event is fired. Returns a `Playwright.SDK.Channel.Event`.

  ## Arguments

  - `event`: Event name; the same as those passed to `Playwright.BrowserContext.on/3`
  - `predicate`: Receives the `Playwright.SDK.Channel.Event` and resolves to a
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
  @doc deprecated: "This function will be removed in favor of `BrowserContext.on/3`."
  @spec expect_event(t(), event(), options(), function()) :: Playwright.SDK.Channel.Event.t() | {:error, Error.t()}
  def expect_event(context, event, options \\ %{}, trigger \\ nil)

  def expect_event(%BrowserContext{session: session} = context, event, options, trigger) do
    Channel.wait(session, {:guid, context.guid}, event, options, trigger)
  end

  @doc """
  Executes `trigger` and waits for a new `Playwright.Page` to be created within
  the `Playwright.BrowserContext`.

  If `predicate` is provided, it passes the `Playwright.Page` value into the
  predicate function, wrapped in `Playwright.SDK.Channel.Event`, and waits for
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
  @doc deprecated: "This function will be removed in favor of `BrowserContext.on/3`."
  def expect_page(%BrowserContext{} = context, options \\ %{}, trigger \\ nil) do
    expect_event(context, :page, options, trigger)
  end

  @doc """
  Adds a function called `name` on the `window` object of every frame in
  every page in the context.

  When evaluated, the function executes `callback` and resolves to the return
  value of the `callback`.

  The first argument to the `callback` function includes the following details
  about the caller:

      %{
        context: %Playwright.BrowserContext{},
        frame:   %Playwright.Frame{},
        page:    %Playwright.Page{}
      }

  See `Playwright.Page.expose_binding/4` for a similar, Page-scoped version.

  ## Usage

  An example of exposing a page URL to all frames in all pages in the context:

      BrowserContext.expose_binding(context, "pageURL", fn %{page: page} ->
        Page.url(page)
      end)

      BrowserContext.new_page(context)
      |> Page.set_content(\"\"\"
        <script>
          async function onClick() {
            document.querySelector("div").textContent = await window.pageURL();
          }
        </script>
        <button onclick="onClick()">Click me</button>
        <div></div>
      \"\"\")
      |> Page.get_by_role("button")
      |> Page.click()

  ## Arguments

  | name       |            | description                     |
  | ---------- | ---------- | ------------------------------- |
  | `context`  |            | The "subject" `BrowserContext`. |
  | `name`     |            | Name of the function on the `window` object. |
  | `callback` |            | Callback function that will be evaluated. |

  ## Returns

  - `Playwright.BrowserContext.t()`
  - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:expose_binding, [:context, :name, :callback]}
  @spec expose_binding(BrowserContext.t(), String.t(), function()) :: t() | {:error, Error.t()}
  def expose_binding(%BrowserContext{session: session} = context, name, callback) do
    Channel.patch(session, {:guid, context.guid}, %{bindings: Map.merge(context.bindings, %{name => callback})})
    Channel.post({context, :expose_binding}, %{name: name, needs_handle: false})
  end

  @doc """
  Adds a function called `name` on the `window` object of every frame in
  every page in the context.

  When evaluated, the function executes `callback` and resolves to the return
  value of the `callback`.

  See `Playwright.Page.expose_function/3` for a similar, Page-scoped version.

  ## Usage

  An example of adding a `sha256` function all pages in the context:

      BrowserContext.expose_function(context, "sha256", fn text ->
        :crypto.hash(:sha256, text)
        |> Base.encode16()
        |> String.downcase()
      end)

      BrowserContext.new_page(context)
      |> Page.set_content(\"\"\"
        <script>
          async function onClick() {
            document.querySelector("div").textContent = await window.sha256("example");
          }
        </script>
        <button onclick="onClick()">Click me</button>
        <div></div>
      \"\"\")
      |> Page.get_by_role("button")
      |> Page.click()

  ## Arguments

  | name       |            | description                     |
  | ---------- | ---------- | ------------------------------- |
  | `context`  |            | The "subject" `BrowserContext`. |
  | `name`     |            | Name of the function on the `window` object. |
  | `callback` |            | Callback function that will be evaluated. |

  ## Returns

  - `Playwright.BrowserContext.t()`
  - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:expose_function, [:context, :name, :callback]}
  @spec expose_function(BrowserContext.t(), String.t(), function()) :: t() | {:error, Error.t()}
  def expose_function(%BrowserContext{} = context, name, callback) do
    expose_binding(context, name, fn _, args ->
      callback.(args)
    end)
  end

  @doc """
  Grants the specified permissions to the browser context.

  If the optional `origin` is provided, only grants the corresponding
  permissions to that origin.

  ## Usage

      BrowserContext.grant_permissions(context, ["geolocation"])
      BrowserContext.grant_permissions(context, ["geolocation"], %{origin: "https://example.com"})

  ## Arguments

  | name          |            | description                     |
  | ------------- | ---------- | ------------------------------- |
  | `context`     |            | The "subject" `BrowserContext`. |
  | `permissions` |            | A permission or list of permissions to grant. |
  | `options`     | (optional) | Options (see below)             |

  ### Available permisions

  Permissions may be any of the following:

  - `'accelerometer'`
  - `'accessibility-events'`
  - `'ambient-light-sensor'`
  - `'background-sync'`
  - `'camera'`
  - `'clipboard-read'`
  - `'clipboard-write'`
  - `'geolocation'`
  - `'gyroscope'`
  - `'magnetometer'`
  - `'microphone'`
  - `'midi'`
  - `'midi-sysex'` (system-exlusive midi)
  - `'notifications'`
  - `'payment-handler'`
  - `'storage-access'`

  ### Options

  | name     |            | description                       |
  | -------- | ---------- | --------------------------------- |
  | `origin` | (optional) | The [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) to which to scope the granted permissions. e.g., "https://example.com" |

  ## Returns

  - `Playwright.BrowserContext.t()`
  - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:grant_permissions, [:context, :permissions]}
  @pipe {:grant_permissions, [:context, :permissions, :options]}
  @spec grant_permissions(t(), permission() | [permission()], opts_permissions()) :: t() | {:error, Playwright.API.Error.t()}
  def grant_permissions(%BrowserContext{} = context, permissions, options \\ %{}) do
    Channel.post({context, :grant_permissions}, %{permissions: List.flatten([permissions])}, options)
  end

  @doc """
  Returns a newly created Chrome DevTools Protocol (CDP) session.

  > #### NOTE {: .info}
  >
  > CDP sessions are only supported in Chromium-based browsers.

  ## Usage

      page = BrowserContext.new_page(context)
      BrowserContext.new_cdp_session(context, page)

  ## Arguments

  | name      |            | description                     |
  | --------- | ---------- | ------------------------------- |
  | `context` |            | The "subject" `BrowserContext`. |
  | `target`  |            | Target for which to create the new CDP session. May be a `Playwright.Page` or a `Playwright.Frame` |

  ## Returns

  - `Playwright.CDPSession.t()`
  - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:new_cdp_session, [:context, :target]}
  @spec new_cdp_session(t(), Frame.t() | Page.t()) :: Playwright.CDPSession.t() | {:error, Error.t()}
  def new_cdp_session(context, target)

  def new_cdp_session(%BrowserContext{} = context, %Frame{} = frame) do
    Channel.post({context, "newCDPSession"}, %{frame: %{guid: frame.guid}})
  end

  def new_cdp_session(%BrowserContext{} = context, %Page{} = page) do
    Channel.post({context, "newCDPSession"}, %{page: %{guid: page.guid}})
  end

  @doc """
  Creates a new `Playwright.Page` in the context.

  ## Usage

      BrowserContext.new_page(context)

  ## Arguments

  | name      |            | description                     |
  | --------- | ---------- | ------------------------------- |
  | `context` |            | The "subject" `BrowserContext`. |

  ## Returns

  - `Playwright.Page.t()`
  - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:new_page, [:context]}
  @spec new_page(t()) :: Page.t() | {:error, Error.t()}
  def new_page(context)

  def new_page(%BrowserContext{} = context) do
    case context.owner_page do
      nil ->
        Channel.post({context, :new_page})

      %Playwright.Page{} ->
        raise(RuntimeError, message: "Please use Playwright.Browser.new_context/1")
    end
  end

  @doc """
  Register a (non-blocking) callback/handler for various types of events.
  """
  @spec on(t(), event(), function()) :: t()
  def on(%BrowserContext{} = context, event, callback) do
    bind!(context, event, callback)
  end

  @doc """
  Returns all open pages in the context.

  ## Usage

      BrowserContext.pages(context)

  ## Arguments

  | name      |            | description                     |
  | --------- | ---------- | ------------------------------- |
  | `context` |            | The "subject" `BrowserContext`. |

  ## Returns

  - `[Page.t()]`
  """
  @spec pages(t()) :: [Page.t()]
  def pages(%BrowserContext{} = context) do
    Channel.list(context.session, {:guid, context.guid}, "Page")
  end

  @doc """
  Routing provides the capability of modifying network requests that are
  initiated by any page in the browser context.

  Once a route is enabled, every request matching the URL pattern will stall
  unless it is continued, fulfilled, or aborted.

  Page routes (set up with `Page.route4`) take precedence over browser context
  routes when the request matches both handlers.

  To remove a route with its handler, use `Playwright.BrowserContext.unroute/3`.

  > #### NOTE {: .info}
  >
  > `Playwright.BrowserContext.route/4` will not intercept requets intercepted
  > by a Service Worker. See [GitHub issue 1010](https://github.com/microsoft/playwright/issues/1090).
  > It is recommended to disable Service Workers when using request interception
  > by setting `:service_workers` to `'block'` when creating a `BrowserContext`.

  > #### NOTE {: .info}
  >
  > Enabling routing disables http caching.

  ## Usage

  An example of a naïve handler that aborts all image requests:

      Browser.new_context(browser)
        |> BrowserContext.route("**/*.{png,jpg,jpeg}", fn route -> Route.abort(route) end)
        |> BrowserContext.new_page()
        |> Page.goto("https://example.com")

      Browser.close(browser)

  An example of examining the request to decide on the route action. For
  example, mocking all requests that contain some post data, and leaving
  all other requests un-modified.

      Browser.new_context(browser)
        |> BrowserContext.route("/api/**", fn route ->
          case Route.request(route) |> Request.post_data() |> Enum.fetch("some-data") do
            {:ok, _} ->
              Route.fulfill(route, %{body: "mock-data"})

            _ ->
              Route.continue(route)
          end
        end)

  ## Arguments

  | name      |            | description                     |
  | --------- | ---------- | ------------------------------- |
  | `context` |            | The "subject" `BrowserContext`. |
  | `url`     |            | A glob pattern, regex pattern, or predicate receiving a [URL](https://nodejs.org/api/url.html) to match against while routing. When a `:base_url` was provided via the context options, and the provided URL is a path, the two are merged. |
  | `handler` |            | The handler function to manage request routing. |
  | `options` | (optional) | Options (see below). |

  ### Options

  | name     |            | description                       |
  | -------- | ---------- | --------------------------------- |
  | `times`  | (optional) | How many times a route should be used. Defaults to every time. |

  ## Returns

  - `BrowserContext.t()`
  - `{:error, Error.t()}`
  """
  @pipe {:route, [:context, :pattern, :handler]}
  @pipe {:route, [:context, :pattern, :handler, :options]}
  @spec route(t(), route_url(), function(), opts_route()) :: t() | {:error, Error.t()}
  def route(context, pattern, handler, options \\ %{})

  def route(%BrowserContext{session: session} = context, pattern, handler, _options) do
    with_latest(context, fn context ->
      matcher = Helpers.URLMatcher.new(pattern)
      handler = Helpers.RouteHandler.new(matcher, handler)

      routes = [handler | context.routes]
      patterns = Helpers.RouteHandler.prepare(routes)

      Channel.patch(session, {:guid, context.guid}, %{routes: routes})
      Channel.post({context, :set_network_interception_patterns}, %{patterns: patterns})
    end)
  end

  # ---

  # @spec route_from_har(t(), binary(), map()) :: t() | {:error, Error.t()}
  # def route_from_har(context, har, options \\ %{})

  # ???
  # @spec service_workers(t()) :: [Playwright.Worker.t()]
  # def service_workers(context)

  @doc """
  Changes the default maximum navigation time for the following calls and
  related shortcuts:

  - `Playwright.Page.go_back/2`
  - `Playwright.Page.go_forward/2`
  - `Playwright.Page.goto/2`
  - `Playwright.Page.reload/2`
  - `Playwright.Page.set_content/3`

  ## Usage

      BrowserContext.set_default_navigation_timeout(context, 1_000)

  ## Arguments

  | name      |            | description                     |
  | --------- | ---------- | ------------------------------- |
  | `context` |            | The "subject" `BrowserContext`. |
  | `timeout` |            | Maximum navigation time in milliseconds. |

  ## Returns

  - `BrowserContext.t()`
  - `{:error, Error. t()}`
  """
  @pipe {:set_default_navigation_timeout, [:context, :timeout]}
  @spec set_default_navigation_timeout(t(), number()) :: t() | {:error, Error.t()}
  def set_default_navigation_timeout(%BrowserContext{} = context, timeout) do
    Channel.post({context, :set_default_navigation_timeout_no_reply}, %{timeout: timeout})
  end

  @doc """
  Changes the default maximum time for the following calls that accept a
  `:timeout` option.

  > #### NOTE {: .info}
  >
  > The following take precedence over this setting:
  >
  > - `Playwright.Page.set_default_navigation_timeout/2`
  > - `Playwright.Page.set_default_timeout/2`
  > - `Playwright.BrowserContext.set_default_navigation_timeout/2`

  ## Usage

      BrowserContext.set_default_timeout(context, 1_000)

  ## Arguments

  | name      |            | description                     |
  | --------- | ---------- | ------------------------------- |
  | `context` |            | The "subject" `BrowserContext`. |
  | `timeout` |            | Maximum navigation time in milliseconds. |

  ## Returns

  - `BrowserContext.t()`
  - `{:error, Error. t()}`
  """
  @pipe {:set_default_timeout, [:context, :timeout]}
  @spec set_default_timeout(t(), number()) :: t() | {:error, Error.t()}
  def set_default_timeout(%BrowserContext{} = context, timeout) do
    Channel.post({context, :set_default_timeout_no_reply}, %{timeout: timeout})
  end

  @doc """
  Configures extra HTTP headers to be sent with every request initiated by any
  page in the context.

  The headers are merged with page-specific extra HTTP headers set with
  `Playwright.Page.set_extra_http_headers/2`. If page overrides a particular
  header, the page-specific header value will be used instead of that from
  the browser context.

  > #### NOTE {: .info}
  >
  > `Playwright.BrowserContext.set_extra_http_headers/2` does not guarantee
  > the order of hedaers in the outgoing requests.

  ## Usage

      BrowserContext.set_extra_http_headers(context, %{referer: "https://example.com"})

  ## Arguments

  | name      |            | description                     |
  | --------- | ---------- | ------------------------------- |
  | `context` |            | The "subject" `BrowserContext`. |
  | `headers` |            | A `map()` containing additional HTTP headers to be sent with every request. All header values must be `String.t()`. |

  ## Returns

  - `BrowserContext.t()`
  - `{:error, Error. t()}`
  """
  @pipe {:set_extra_http_headers, [:context, :headers]}
  @spec set_extra_http_headers(t(), map()) :: t() | {:error, Error.t()}
  def set_extra_http_headers(%BrowserContext{} = context, headers) do
    Channel.post({context, "setExtraHTTPHeaders"}, %{headers: serialize_headers(headers)})
  end

  @doc """
  Sets the context's geolocation.

  Passing `nil` emulates position unavailable.

  > #### NOTE {: .info}
  >
  > Consider using `Playwright.BrowserContext.grant_permissions/3` to grant
  > permissions for the browser context pages to read geolocation.

  > #### WARNING! {: .warning}
  >
  > As of 2024-10-09, this function has not yet been successfully tested.
  > So far, the test runs have failed to receive location data and instead
  > experiences "error code 2", which [reportedly](https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPositionError/code)
  > represents `POSITION_UNAVAILABLE` - "The acquisition of the geolocation
  > failed because one or several internal sources of position returned an internal error."

  ## Usage

      BrowserContext.set_geolocation(context, %{
        latitude: 59.95,
        longitude: 30.31667
      })

  ## Arguments

  | name          |            | description                     |
  | ------------- | ---------- | ------------------------------- |
  | `context`     |            | The "subject" `BrowserContext`. |
  | `geolocation` |            | `BrowserContext.geolocation()`. |

  ### Geolocation settings

  | name        |            | description                         |
  | ----------- | ---------- | ----------------------------------- |
  | `latitude`  |            | Latitude between `-90` and `90`.    |
  | `lingitude` |            | Longitude between `-180` and `180`. |
  | `accuracy`  | (optional) | Non-negative accuracy value. Defaults to `0`. |

  ## Returns

  - `BrowserContext.t()`
  - `{:error, Error. t()}`
  """
  @pipe {:set_geolocation, [:context, :geolocation]}
  @spec set_geolocation(t(), geolocation() | nil) :: t() | {:error, Error.t()}
  def set_geolocation(context, params \\ nil)

  def set_geolocation(%BrowserContext{} = context, params) when is_map(params) do
    Channel.post({context, :set_geolocation}, params)
  end

  def set_geolocation(%BrowserContext{} = context, nil) do
    Channel.post({context, :set_geolocation})
  end

  @spec set_offline(t(), boolean()) :: t() | {:error, Error.t()}
  def set_offline(%BrowserContext{} = context, offline) do
    Channel.post({context, :set_offline}, %{offline: offline})
  end

  # ---

  # @spec storage_state(t(), String.t()) :: storage_state()
  # def storage_state(context, path \\ nil)

  # ---

  @spec unroute(t(), binary(), function() | nil) :: t() | {:error, Error.t()}
  def unroute(%BrowserContext{session: session} = context, pattern, callback \\ nil) do
    with_latest(context, fn context ->
      remaining =
        Enum.filter(context.routes, fn handler ->
          handler.matcher.match != pattern || (callback && handler.callback != callback)
        end)

      Channel.patch(session, {:guid, context.guid}, %{routes: remaining})
    end)
  end

  # @spec unroute_all(t(), map()) :: t() | {:error, Error.t()}
  # def unroute_all(context, options \\ %{})

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

  defp serialize_headers(headers) when is_map(headers) do
    Enum.into(headers, [], fn {name, value} ->
      %{name: name, value: value}
    end)
  end
end
