defmodule Playwright.BrowserType do
  @moduledoc """
  `Playwright.BrowserType` provides functions to launch a specific browser
  instance or connect to an existing one.

  The following is a typical example of using Playwright to drive automation:

      alias Playwright.{Browser, BrowserType, Page}

      {session, browser} = BrowserType.launch(:chromium)
      page = Browser.new_page(browser)

      Page.goto(page, "https://example.com")
      # other actions...

      Browser.close(browser)

  ## Example

  Open a new chromium via the CLI driver:

      {session, browser} = Playwright.BrowserType.launch()

  Connect to a running playwright instances:

      {session, browser} =
        Playwright.BrowserType.connect("ws://localhost:3000/playwright")
  """

  use Playwright.ChannelOwner
  alias Playwright.{BrowserType, Config, Transport}
  alias Playwright.Channel.Session

  @typedoc "The web client type used for `launch/1` and `connect/2` functions."
  @type client :: :chromium | :firefox | :webkit

  @typedoc "Options for `connect/2`"
  @type connect_options :: map()

  @typedoc "A map/struct providing call options"
  @type options :: map()

  @typedoc "A string URL"
  @type url :: String.t()

  @typedoc "A websocket endpoint (URL)"
  @type ws_endpoint :: url()

  @doc """
  Attaches Playwright to an existing browser instance over a websocket.

  ## Returns

    - `{session, %Playwright.Browser{}}`

  ## Arguments

  | key/name    | type   |                             | description |
  | ------------- | ------ | --------------------------- | ----------- |
  | `ws_endpoint` | param  | `BrowserType.ws_endpoint()` | A browser websocket endpoint to connect to. |
  | `:headers`    | option | `map()`                     | Additional HTTP headers to be sent with websocket connect request |
  | `:slow_mow`   | option | `integer()`                 | Slows down Playwright operations by the specified amount of milliseconds. Useful so that you can see what is going on. `(default: 0)` |
  | `:logger`     | option |                             | Logger sink for Playwright logging |
  | `:timeout`    | option | `integer()`                 | Maximum time in milliseconds to wait for the connection to be established. Pass `0` to disable timeout. `(default: 30_000 (30 seconds))` |
  """
  @spec connect(ws_endpoint(), connect_options()) :: {pid(), Playwright.Browser.t()}
  def connect(ws_endpoint, options \\ %{})

  def connect(ws_endpoint, _options) do
    with {:ok, session} <- new_session(Transport.WebSocket, [ws_endpoint]),
         %{guid: guid} <- launched_browser(session),
         browser <- Channel.find(session, {:guid, guid}) do
      {session, browser}
    else
      {:error, error} -> {:error, {"Error connecting to #{inspect(ws_endpoint)}", error}}
      error -> {:error, {"Error connecting to #{inspect(ws_endpoint)}", error}}
    end
  end

  @doc """
  Attaches Playwright to an existing browser instance using the Chrome DevTools Protocol.

  ## Returns

    - `{session, %Playwright.Browser{}}`

  ## Arguments

    ... (many)

  ## Example

      {_, browser} = Playwright.BrowserType.connect_over_cdp(:chromium, "http://127.0.0.1:9222")

  """
  @spec connect_over_cdp(client(), url(), options()) :: Playwright.Browser.t()
  def connect_over_cdp(client, endpoint_url \\ nil, options \\ %{})

  def connect_over_cdp(client, endpoint_url, options)
      when is_atom(client)
      when client in [:chromium] do
    with {:ok, session} <- new_session(Transport.Driver, options),
         browser_type <- chromium(session),
         browser <- _connect_over_cdp(browser_type, Map.merge(%{"endpointURL" => endpoint_url}, options)) do
      {session, browser}
    end
  end

  def connect_over_cdp(client, _endpoint_url, _options)
      when is_atom(client)
      when client in [:firefox, :webkit] do
    raise RuntimeError, message: "not yet implemented"
  end

  defp _connect_over_cdp(%BrowserType{session: session, guid: guid}, params) do
    %{browser: browser, default_context: browser_context} = Channel.post(session, {:guid, guid}, "connectOverCDP", params)
    if browser_context, do: Channel.patch(browser_context.session, {:guid, browser_context.guid}, %{browser: browser})
    browser
  end

  # @spec executable_path(BrowserType.t()) :: String.t()
  # def executable_path(browser_type)

  # ---

  @doc """
  Launches a new browser instance via the Playwright driver CLI.

  ## Example

      # Use `:ignore_default_args` option to filter out `--mute-audio` from
      # default arguments:
      browser =
        Playwright.launch(:chromium, %{ignore_default_args = ["--mute-audio"]})

  ## Returns

    - `{session, %Playwright.Browser{}}`

  ## Arguments

  ... (many)

  ## NOTE

  > **Chromium-only** Playwright can also be used to control the Google Chrome
  > or Microsoft Edge browsers, but it works best with the version of Chromium
  > it is bundled with. There is no guarantee it will work with any other
  > version. Use `:executable_path` option with extreme caution.
  >
  > If Google Chrome (rather than Chromium) is preferred, a
  > [Chrome Canary](https://www.google.com/chrome/browser/canary.html) or
  > [Dev Channel](https://www.chromium.org/getting-involved/dev-channel) build
  > is suggested.
  >
  > Stock browsers like Google Chrome and Microsoft Edge are suitable for tests
  > that require proprietary media codecs for video playback.
  > See [this article](https://www.howtogeek.com/202825/what%E2%80%99s-the-difference-between-chromium-and-chrome/)
  > for other differences between Chromium and Chrome.
  > [This article](https://chromium.googlesource.com/chromium/src/+/lkgr/docs/chromium_browser_vs_google_chrome.md)
  > describes some differences for Linux users.
  """
  @spec launch(client() | nil, any()) :: {pid(), Playwright.Browser.t()}
  def launch(client \\ nil, options \\ Config.launch_options(true))

  def launch(nil, options) do
    launch(:chromium, options)
  end

  def launch(client, options)
      when is_atom(client)
      when client in [:chromium] do
    with {:ok, session} <- new_session(Transport.Driver, options),
         browser_type <- chromium(session),
         browser <- browser(browser_type, options) do
      {session, browser}
    end
  end

  def launch(client, _options)
      when is_atom(client)
      when client in [:firefox, :webkit] do
    raise RuntimeError, message: "not yet implemented"
  end

  def launch(options, _) do
    launch(nil, options)
  end

  # ---

  # @spec launch_persistent_context(BrowserType.t(), String.t(), options()) :: Playwright.BrowserContext.t()
  # def launch_persistent_context(browser_type, user_data_dir, options \\ %{})

  # @spec launch_server(BrowserType.t(), options()) :: Playwright.BrowserServer.t()
  # def launch_server(browser_type, options \\ %{})

  # @spec name(BrowserType.t()) :: client()
  # def name(browser_type)

  # ---

  # private
  # ----------------------------------------------------------------------------

  defp browser(%BrowserType{} = browser_type, launch_options) do
    Channel.post(browser_type.session, {:guid, browser_type.guid}, :launch, launch_options)
  end

  defp chromium(session) do
    playwright = playwright(session)
    %{guid: guid} = playwright.chromium
    Channel.find(session, {:guid, guid})
  end

  defp new_session(transport, args) do
    DynamicSupervisor.start_child(
      Session.Supervisor,
      {Session, {transport, args}}
    )
  end

  defp launched_browser(session) do
    playwright = playwright(session)
    playwright.initializer.preLaunchedBrowser
  end

  defp playwright(session) do
    case Channel.find(session, {:guid, "Playwright"}) do
      %Playwright{} = playwright ->
        playwright

      other ->
        raise("expected to return a `Playwright`, received: #{inspect(other)}")
    end
  end
end
