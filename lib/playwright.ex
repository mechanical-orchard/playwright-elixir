defmodule Playwright do
  @moduledoc """
  `Playwright` launches and manages with Playwright browser-server instances.

  An example of using `Playwright` to drive automation:

  ## Example

      alias Playwright.API.{Browser, Page, Response}

      {:ok, session, browser}  = Playwright.launch(:chromium)
      {:ok, page} = Browser.new_page(browser)
      {:ok, response} = Page.goto(browser, "http://example.com")

      assert Response.ok(response)

      Browser.close(browser)
  """

  use Playwright.SDK.ChannelOwner
  alias Playwright
  alias Playwright.APIRequest
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

  # API
  # ---------------------------------------------------------------------------

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
  | `options` | param | `options()` | `Playwright.SDK.Config.connect_options()` |
  """
  @spec launch(client(), Config.connect_options() | map()) :: {:ok, Playwright.Browser.t()}
  def connect(client, options \\ %{}) do
    options = Map.merge(Config.connect_options(), options)
    {:ok, session} = new_session(Playwright.SDK.Transport.WebSocket, options)
    {:ok, browser} = new_browser(session, client, options)
    {:ok, session, browser}
  end

  @doc """
  Initiates an instance of `Playwright.Browser` use the Driver transport.

  ## Returns

    - `{:ok, Playwright.Browser.t()}`

  ## Arguments

  | key/name  | type  |             | description |
  | ----------| ----- | ----------- | ----------- |
  | `client`  | param | `client()`  | The type of client (browser) to launch. |
  | `options` | param | `options()` | `Playwright.SDK.Config.launch_options()` |
  """
  @spec launch(client(), Config.launch_options() | map()) :: {:ok, Playwright.Browser.t()}
  def launch(client, options \\ %{}) do
    options = Map.merge(Config.launch_options(), options)
    {:ok, session} = new_session(Playwright.SDK.Transport.Driver, options)
    {:ok, browser} = new_browser(session, client, options)
    {:ok, session, browser}
  end

  def request(session) do
    APIRequest.new(session)
  end

  # private
  # ----------------------------------------------------------------------------

  defp new_browser(session, client, options)
       when is_atom(client) and client in [:chromium, :firefox, :webkit] do
    with play <- Channel.find(session, {:guid, "Playwright"}),
         guid <- Map.get(play, client)[:guid] do
      playwright = %Playwright{
        guid: guid,
        session: session
      }

      {:ok, Channel.post({playwright, :launch}, options)}
    end
  end

  defp new_session(transport, args) do
    DynamicSupervisor.start_child(
      Channel.Session.Supervisor,
      {Channel.Session, {transport, args}}
    )
  end
end
