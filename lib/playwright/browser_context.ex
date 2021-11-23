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
      {:ok, context} = Playwright.Browser.new_context(browser)

      # create and use a new page within that context:
      {:ok, page} = Playwright.BrowserContext.new_page(context)
      {:ok, resp} = Playwright.Page.goto(page, "https://example.com")

      # dispose the context once it's no longer needed:
      Playwright.BrowserContext.close(context)

  ## Regarding `expect_event/5` and `on/3`

  The first argument given to `on/3` and `expect_event/5` functions is the
  "owner" on which to bind the event.

  The second argument is the event type.

  The third argument is a callback function that will be executed when the
  event fires, and is passed an instance of `Playwright.Runner.EventInfo`.

  ### Details for `expect_event/5`

  Calls to `expect_event/5` are blocking. These functions take a "trigger",
  execution of which is expected to result in the event being fired.

  If the event does not fire within the timeout window, the call to
  `expect_event/5` will timeout.

  An optional "predicate" function may be provided, in which case the fired
  event will be sent to the predicate, which must return a "truthy" result
  in order for the expectation to be fulfilled.

      {:ok, e } = BrowserContext.expect_event(context, :close, fn ->
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
      > - Service workers are only supported on Chromium-based browsers.
  """

  # ---

  use Playwright.ChannelOwner,
    fields: [:browser, :owner_page]

  alias Playwright.{BrowserContext, ChannelOwner, Page}
  alias Playwright.Runner.Channel

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
  def init(%BrowserContext{} = owner, _initializer) do
    {:ok, %{owner | browser: owner.parent}}
  end

  # API
  # ---------------------------------------------------------------------------

  @doc """
  Adds cookies into this `Playwright.BrowserContext`.

  All pages within this context will have these cookies installed. Cookies can
  be obtained via `Playwright.BrowserContext.cookies/1`.

  ## Example

      :ok = BrowserContext.add_cookies(context, [cookie_1, cookie_2])

  ## Cookie fields

  | key         | description |
  | ----------  | ----------- |
  | `:name`     | |
  | `:value`    | |
  | `:url`      | *(optional)* either url or domain / path are required |
  | `:domain`   | *(optional)* either url or domain / path are required |
  | `:path`     | *(optional)* either url or domain / path are required |
  | `:expires`  | *(optional)* Unix time in seconds. |
  | `:httpOnly` | *(optional)* |
  | `:secure`   | *(optional)* |
  | `:sameSite` | *(optional)* one of "Strict", "Lax", "None" |
  """
  @spec add_cookies(BrowserContext.t(), [cookie]) :: :ok
  def add_cookies(owner, cookies)

  def add_cookies(%BrowserContext{} = owner, cookies) do
    {:ok, _} = Channel.post(owner, :add_cookies, %{cookies: cookies})
    :ok
  end

  # ---

  # @spec add_init_script(BrowserContext.t(), binary(), options()) :: :ok
  # def add_init_script(owner, script, options \\ %{})

  # @spec background_pages(BrowserContext.t()) :: {:ok, [Playwright.Page.t()]}
  # def background_pages(owner)

  # @spec browser(BrowserContext.t()) :: {:ok, Playwright.Browser.t()}
  # def browser(owner)

  # @spec clear_cookies(BrowserContext.t()) :: :ok
  # def clear_cookies(owner)

  # @spec clear_permissions(BrowserContext.t()) :: :ok
  # def clear_permissions(owner)

  # ---

  @doc """
  Closes the `Playwright.BrowserContext`. All pages that belong to the
  `Playwright.BrowserContext` will be closed.

  > NOTE:
  > - The default browser context cannot be closed.
  """
  @spec close(BrowserContext.t()) :: :ok
  def close(%BrowserContext{} = owner) do
    {:ok, _} = Channel.post(owner, :close)
    :ok
  end

  def close({:ok, owner}) do
    close(owner)
  end

  @doc """
  Returns cookies for the `Playwright.BrowserContext`.

  If no URLs are specified, this method returns all cookies. If URLs are
  specified, only cookies that affect those URLs are returned.

  | param  | description |
  | ------ | ----------- |
  | `urls` | *(optional)* List of URLs |

  See `add_cookies/2` for cookie field details.
  """
  @spec cookies(BrowserContext.t(), url | [url]) :: {:ok, [cookie]}
  def cookies(owner, urls \\ [])

  def cookies(%BrowserContext{} = owner, urls) do
    Channel.post(owner, :cookies, %{urls: urls})
  end

  @doc """
  Waits for an event to fire (i.e., is blocking) and passes its value into the
  predicate function.

  Returns when the predicate returns a truthy value. Throws an error if the
  context closes before the event is fired. Returns a `Playwright.Runner.EventInfo`.

  ## Arguments

  - `event`: Event name; the same as those passed to `Playwright.BrowserContext.on/3`
  - `predicate`: Receives the `Playwright.Runner.EventInfo` and resolves to a
    "truthy" value when the waiting should resolve.
  - `options`:
    - `predicate`: ...
    - `timeout`: The maximum time to wait in milliseconds. Defaults to 30000
      (30 seconds). Pass 0 to disable timeout. The default value can be changed
      via `Playwright.BrowserContext.set_default_timeout/2`.

  ## Example

      {:ok, event_info} = BrowserContext.expect_event(owner, :page, fn ->
        BrowserContext.new_page(owner)
      end)

  > NOTE:
  > - The "throw an error if the context closes..." is not yet implemented.
  > - The handling of :predicate is not yet implemented.
  """
  @spec expect_event(BrowserContext.t() | Page.t(), atom() | binary(), fun(), function_or_options(), map()) ::
          {:ok, Playwright.Runner.EventInfo.t()}
  def expect_event(owner, event, trigger, predicate \\ nil, options \\ %{})

  def expect_event(%BrowserContext{} = owner, event, trigger, _predicate, _options)
      when is_function(trigger) do
    Channel.wait_for(owner, event, trigger)
  end

  def expect_event(%BrowserContext{} = owner, event, trigger, options, _)
      when is_map(options) do
    expect_event(owner, event, trigger, nil, options)
  end

  def expect_event(%Page{} = owner, event, trigger, predicate, options) do
    Page.context(owner) |> expect_event(event, trigger, predicate, options)
  end

  # def expect_event({:ok, owner}, event, trigger, predicate, options) do
  #   expect_event(owner, event, trigger, predicate, options)
  # end

  defdelegate wait_for_event(owner, event, trigger, predicate \\ nil, options \\ %{}), to: __MODULE__, as: :expect_event

  @doc """
  Executes `trigger` and waits for a new `Playwright.Page` to be created within
  the `Playwright.BrowserContext`.

  If `predicate` is provided, it passes the `Playwright.Page` value into the
  predicate function, wrapped in `Playwright.Runner.EventInfo`, and waits for
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

  > NOTE:
  > - The handling of `predicate` is not yet implemented.
  > - The handling of `timeout` is not yet implemented.
  """
  @spec expect_page(BrowserContext.t(), fun(), function_or_options(), map()) :: {:ok, Playwright.Runner.EventInfo.t()}
  def expect_page(owner, trigger, predicate \\ nil, options \\ %{})

  def expect_page(%BrowserContext{} = owner, trigger, predicate, options)
      when is_function(trigger) do
    expect_event(owner, :page, trigger, predicate, options)
  end

  def expect_page(%BrowserContext{} = owner, trigger, options, _)
      when is_map(options) do
    expect_page(owner, trigger, nil, options)
  end

  defdelegate wait_for_page(owner, trigger, predicate \\ nil, options \\ %{}), to: __MODULE__, as: :expect_page

  # ---

  # @spec expose_binding(BrowserContext.t(), String.t(), function(), options()) :: :ok
  # def expose_binding(owner, name, callback, options \\ %{})

  # @spec expose_function(BrowserContext.t(), String.t(), function()) :: :ok
  # def expose_function(owner, name, callback)

  # @spec grant_permissions(BrowserContext.t(), [String.t()], options()) :: :ok
  # def grant_permissions(owner, permission, options \\ %{})

  # @spec new_cdp_session(BrowserContext.t(), Page.t()) :: {:ok, Playwright.CDPSession.t()}
  # def new_cdp_session(owner, page)

  # ---

  @doc """
  Creates a new `Playwright.Page` in the context.

  If the context is already "owned" by a `Playwright.Page` (i.e., was created
  as a side effect of `Playwright.Browser.new_page/1`), will raise an error
  because there should be a 1-to-1 mapping in that case.
  """
  @spec new_page(t() | {:ok, t()}) :: {:ok, Page.t()}
  def new_page(owner)

  def new_page(%BrowserContext{} = owner) do
    case owner.owner_page do
      nil ->
        Channel.post(owner, :new_page)

      %Playwright.Page{} ->
        raise(RuntimeError, message: "Please use Playwright.Browser.new_context/1")
    end
  end

  def new_page({:ok, owner}) do
    new_page(owner)
  end

  # ---

  # @spec pages(BrowserContext.t()) :: {:ok, [Page.t()]}
  # def pages(owner)

  # ---

  @doc """
  Register a (non-blocking) callback/handler for various types of events.
  """
  @spec on(BrowserContext.t(), event(), function()) :: {:ok, BrowserContext.t()}
  def on(%BrowserContext{} = owner, event, callback) do
    Channel.bind(owner, event, callback)
  end

  # ---

  # @spec route(BrowserContext.t(), String.t(), function(), options()) :: :ok
  # def route(owner, url_pattern, handler, options \\ %{})

  # @spec service_workers(BrowserContext.t()) :: {:ok, [Playwright.Worker.t()]}
  # def service_workers(owner)

  # @spec set_default_navigation_timeout(BrowserContext.t(), number()) :: :ok
  # def set_default_navigation_timeout(owner, timeout)

  # @spec set_default_imeout(BrowserContext.t(), number()) :: :ok
  # def set_default_imeout(owner, timeout)

  # @spec set_extra_http_headers(BrowserContext.t(), headers()) :: :ok
  # def set_extra_http_headers(owner, headers)

  # @spec set_geolocation(BrowserContext.t(), geolocation()) :: :ok
  # def set_geolocation(owner, geolocation)

  # @spec set_http_credentials(BrowserContext.t(), http_credentials()) :: :ok
  # def set_http_credentials(owner, http_credentials)

  # @spec set_offline(BrowserContext.t(), boolean()) :: :ok
  # def set_offline(owner, offline)

  # @spec storage_state(BrowserContext.t(), String.t()) :: {:ok, storage_state()}
  # def storage_state(owner, path \\ nil)

  # @spec route(BrowserContext.t(), String.t(), options()) :: :ok
  # def route(owner, url_pattern, options \\ %{})

  # ---
end
