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

  @property :chromium
  @property :firefox
  @property :webkit

  @typedoc "The web client type used for `launch` and `connect` functions."
  @type client :: :chromium | :firefox | :webkit

  @typedoc "Options for `launch` and `connect` functions."
  @type options :: Playwright.SDK.Config.launch_options()

  @doc """
  Launches an instance of `Playwright.Browser`.

  ## Returns

    - `{:ok, Playwright.Browser.t()}`

  ## Arguments

  | key/name  | typ   |             | description |
  | ----------| ----- | ----------- | ----------- |
  | `type`    | param | `client()`  | The type of client (browser) to launch. |
  | `options` | param | `options()` | `Playwright.SDK.Config.launch_options()` |
  """
  @spec launch(client(), options() | map()) :: {:ok, Playwright.Browser.t()}
  def launch(client, options \\ %{}) do
    options = Map.merge(Playwright.SDK.Config.launch_options(), options)
    {:ok, session} = new_session(Playwright.SDK.Transport.Driver, options)
    {:ok, browser} = new_browser(session, client, options)
    {:ok, browser}
  end

  # private
  # ----------------------------------------------------------------------------

  defp new_browser(session, client, options)
       when is_atom(client) and client in [:chromium, :firefox, :webkit] do
    with play <- Playwright.SDK.Channel.find(session, {:guid, "Playwright"}),
         guid <- Map.get(play, client)[:guid] do
      {:ok, Playwright.SDK.Channel.post(session, {:guid, guid}, :launch, options)}
    end
  end

  defp new_session(transport, args) do
    DynamicSupervisor.start_child(
      Playwright.SDK.Channel.Session.Supervisor,
      {Playwright.SDK.Channel.Session, {transport, args}}
    )
  end
end
