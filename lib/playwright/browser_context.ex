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
  """

  use Playwright.ChannelOwner,
    fields: [:browser, :owner_page]

  alias Playwright.{BrowserContext, ChannelOwner, Page}
  alias Playwright.Runner.Channel

  @typedoc """
  Any map/struct that contains recognized cookie fields.

  Fields:

  -  `name`
  -  `value`
  -  `url`: either url or domain / path are required. Optional.
  -  `domain`: either url or domain / path are required Optional.
  -  `path`: either url or domain / path are required Optional.
  -  `expires`: Unix time in seconds. Optional.
  -  `httpOnly` Optional.
  -  `secure` Optional.
  -  `sameSite` ("Strict" | "Lax" | "None") Optional.
  """
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

  @type function_or_options :: fun() | options() | nil
  @type options :: map()

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
  Creates a new `Playwright.Page` in the `Playwright.BrowserContext`.

  If the context is already "owned" by a `Playwright.Page` (i.e., was created
  as a side effect of `Playwright.Browser.new_page/1`), will raise an error
  because there should be a 1-to-1 mapping in that case.
  """
  @spec new_page(BrowserContext.t()) :: {:ok, Page.t()}
  def new_page(%BrowserContext{} = owner) do
    case owner.owner_page do
      nil ->
        Channel.post(owner, :new_page)

      %Playwright.Page{} ->
        raise(RuntimeError, message: "Please use Playwright.Browser.new_context/1")
    end
  end

  @doc """
  Adds cookies into this `Playwright.BrowserContext`.

  All pages within this context will have these cookies installed. Cookies can
  be obtained via `Playwright.BrowserContext.cookies/1`.

  ## Example

      :ok = BrowserContext.add_cookies(owner, [cookie_1, cookie_2])
  """
  @spec add_cookies(BrowserContext.t(), [cookie]) :: :ok
  def add_cookies(owner, cookies)

  def add_cookies(%BrowserContext{} = owner, cookies) do
    {:ok, _} = Channel.post(owner, :add_cookies, %{cookies: cookies})
    :ok
  end

  @doc """
  Closes the `Playwright.BrowserContext`.

  All pages that belong to the `Playwright.BrowserContext` will be closed.

  > NOTE:
  > - The default browser context cannot be closed.
  """
  @spec close(BrowserContext.t()) :: :ok
  def close(%BrowserContext{} = owner) do
    {:ok, _} = Channel.post(owner, :close)
    :ok
  end

  @doc """
  Returns cookies for the `Playwright.BrowserContext`.

  If URLs are specified, only cookies that affect those URLs are returned.
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
    expect_event(Page.context(owner), event, trigger, predicate, options)
  end

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

  @doc """
  Register a callback/handler for various types of events.

  ## Events

  - `:background_page`: Emitted when a new background page is created in the context.
    > NOTE:
    > - Only works with Chromium browser's persistent context.
        ...
  - `:close`: ...
  - `:page`: ...
  - `:request`: ...
  - `:requestfailed`: ...
  - `:requestfinished`: ...
  - `:response`: ...
  - `:serviceworker`: ...
  """

  @spec on(BrowserContext.t(), atom() | binary(), function()) :: {:ok, BrowserContext.t()}
  def on(%BrowserContext{} = owner, event, callback) do
    Channel.bind(owner, event, callback)
  end
end
