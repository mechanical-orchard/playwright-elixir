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

  Connect to a running playwright instance:

      {session, browser} =
        Playwright.BrowserType.connect("ws://localhost:3000/playwright")
  """

  use Playwright.SDK.ChannelOwner
  alias Playwright.BrowserType
  alias Playwright.SDK.{Channel, Config, Transport}

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

  # ---

  # @spec connect_over_cdp(BrowserType.t(), url(), options()) :: Playwright.Browser.t()
  # def connect_over_cdp(browser_type, endpoint_url, options \\ %{})

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
  def launch(client \\ nil, options \\ %{})

  def launch(nil, options) do
    launch(:chromium, options)
  end

  def launch(client, options)
      when is_atom(client) and client in [:chromium] do
    {:ok, session} = new_session(Transport.Driver, options)
    {session, chromium(session)}
  end

  def launch(client, _options)
      when is_atom(client) and client in [:firefox, :webkit] do
    raise RuntimeError, message: "not yet implemented: #{inspect(client)}"
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

  defp browser(%BrowserType{} = browser_type) do
    Channel.post(browser_type.session, {:guid, browser_type.guid}, :launch, Config.launch_options())
  end

  defp chromium(session) do
    case Channel.find(session, {:guid, "Playwright"}) do
      %Playwright{} = playwright ->
        %{guid: guid} = playwright.chromium
        Channel.find(session, {:guid, guid}) |> browser()

      other ->
        raise("expected chromium to return a  `Playwright`, received: #{inspect(other)}")
    end
  end

  defp new_session(transport, args) do
    DynamicSupervisor.start_child(
      Channel.Session.Supervisor,
      {Channel.Session, {transport, args}}
    )
  end

  defp launched_browser(session) do
    playwright = Channel.find(session, {:guid, "Playwright"})
    playwright.initializer.preLaunchedBrowser
  end
end
