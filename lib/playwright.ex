defmodule Playwright do
  @moduledoc """
  `Playwright` module provides functions to launch a `Playwright.Browser`.

  The following is a typical example of using `Playwright` to drive automation.

  ## Example

      alias Playwright.{Browser, Page, Response}

      browser = Playwright.launch(:chromium)

      assert Browser.new_page(browser)
      |> Page.goto("http://example.com")
      |> Response.ok()

      Browser.close(browser)
  """

  use Playwright.ChannelOwner

  @property :chromium

  @typedoc "The web client type used for `launch` and `connect` functions."
  @type client_type :: :chromium | :firefox | :webkit

  @doc """
  Launch an instance of `Playwright.Browser`.

  ## Arguments

  - `type`: The type of client (browser) to launch.
    `(:chromium | nil)` with default `:chromium`
  """
  @spec launch(client_type() | nil) :: Playwright.Browser.t()
  def launch(type \\ nil)

  def launch(nil), do: launch(:chromium)

  def launch(type) when type in [:chromium, :firefox, :webkit] do
    options = Playwright.Config.launch_options()

    {_session, browser} = Playwright.BrowserType.launch(type, options)
    # {_session, browser} = Playwright.Channel.Session.launch(type, options)

    browser
  end
end
