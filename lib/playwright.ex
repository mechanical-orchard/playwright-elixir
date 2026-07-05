defmodule Playwright do
  @moduledoc """
  `Playwright` launches and manages with Playwright browser-server instances.

  An example of using `Playwright` to drive automation:

  ## Example

      alias Playwright.API.{Browser, Page, Response}

      {:ok, browser}  = Playwright.launch(:chromium)
      {:ok, page}     = Browser.new_page(browser)
      {:ok, response} = Page.goto(browser, "http://example.com")

      assert Response.ok(response)

      Browser.close(browser)
  """

  use Playwright.SDK.ChannelOwner
  alias Playwright.SDK.Channel
  alias Playwright.SDK.Config

  @property :chromium
  @property :firefox
  @property :webkit

  @typedoc "The web client type used for `launch` and `connect` functions."
  @type client :: :chromium | :firefox | :webkit

  #   @typedoc "Options for `connect`."
  #   @type connect_options :: Playwright.SDK.Config.connect_options()
  #
  #   @typedoc "Options for `launch`."
  #   @type launch_options :: Playwright.SDK.Config.launch_options()

  @doc """
  Initiates an instance of `Playwright.Browser` use the WebSocket transport.

  Note that this approach assumes the a Playwright Server is running and
  handling WebSocket requests at the configured `ws_endpoint`.

  ## Returns

    - `{:ok, Playwright.Browser.t()}`

  ## Arguments

  | key/name  | typ   |             | description |
  | ----------| ----- | ----------- | ----------- |
  | `client`  | param | `client()`  | The type of client (browser) to launch. |
  | `options` | param | `options()` | Connection options (see Config module) |
  """
  @spec connect(client(), map()) :: {:ok, Playwright.Browser.t()}
  def connect(client, options \\ %{})
      when is_atom(client) and client in [:chromium, :firefox, :webkit] do
    options =
      Config.connect_options()
      |> Map.merge(options)
      |> Map.put(:browser, client)

    {:ok, session} = new_session(Playwright.SDK.Transport.WebSocket, options)

    # The session shuts down if the server reports a connection-level error
    # (e.g., it fails to launch the requested browser), in which case the
    # lookup of the pre-launched browser exits with `:noproc`.
    try do
      {:ok, connected_browser(session)}
    catch
      :exit, reason -> {:error, {:connect, client, reason}}
    end
  end

  @doc """
  Initiates an instance of `Playwright.Browser` use the Driver transport.

  ## Returns

    - `{:ok, Playwright.Browser.t()}`

  ## Arguments

  | key/name  | typ   |             | description |
  | ----------| ----- | ----------- | ----------- |
  | `client`  | param | `client()`  | The type of client (browser) to launch. |
  | `options` | param | `options()` | Launch options (see Config module) |
  """
  @spec launch(client(), map()) :: {:ok, Playwright.Browser.t()}
  def launch(client, options \\ %{}) do
    options = Map.merge(Config.launch_options(), options)
    {:ok, session} = new_session(Playwright.SDK.Transport.Driver, options)
    {:ok, browser} = new_browser(session, client, options)
    {:ok, browser}
  end

  # private
  # ----------------------------------------------------------------------------

  defp new_browser(session, client, options)
       when is_atom(client) and client in [:chromium, :firefox, :webkit] do
    with play <- Channel.find(session, {:guid, "Playwright"}),
         guid <- Map.get(play, client)[:guid] do
      {:ok, Channel.post(session, {:guid, guid}, :launch, options)}
    end
  end

  # The server pre-launches a browser for the connection (selected via the
  # "x-playwright-browser" upgrade header) and does not allow launching more,
  # so attach to that browser rather than posting a launch request.
  defp connected_browser(session) do
    playwright = Channel.find(session, {:guid, "Playwright"})
    %{guid: guid} = playwright.initializer.preLaunchedBrowser
    Channel.find(session, {:guid, guid})
  end

  defp new_session(transport, args) do
    DynamicSupervisor.start_child(
      Playwright.SDK.Channel.Session.Supervisor,
      {Playwright.SDK.Channel.Session, {transport, args}}
    )
  end
end
