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

  use Playwright.Runner.ChannelOwner

  @typedoc """
  The web client type used for `launch` and `connect` functions.
  """
  @type client :: :chromium | :firefox | :webkit

  @doc """
  Launch an instance of `Playwright.Browser` of the default client type (:chromium).
  """
  def launch do
    launch(:chromium)
  end

  @doc """
  Launch an instance of `Playwright.Browser` given a client type.
  """
  @spec launch(client) :: Playwright.Browser.t()
  def launch(client) when client in [:chromium, :firefox, :webkit] do
    {_connection, browser} = Playwright.BrowserType.launch()
    browser
  end
end
