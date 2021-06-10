defmodule Playwright.BrowserType do
  @moduledoc """
  The `Playwright.BrowserType` module exposes functions that either:
    * launch a new browser instance via a port
    * connect to a running playwright websocket

  ## Examples

  Open a new chromium via the CLI driver:

      {connection, browser} = Playwright.BrowserType.launch()

  Connect to a running playwright instances:

      {connection, browser} = Playwright.BrowserType.connect("ws://localhost:3000/playwright")

  """
  alias Playwright.{BrowserType, ChannelOwner, Connection, Transport}
  require Logger

  # API
  # ----------------------------------------------------------------------------

  @doc """
  Connect to a running playwright server.
  """
  @spec connect(binary()) :: {pid(), ChannelOwner.Browser.t()}
  def connect(ws_endpoint) do
    {:ok, connection} = new_session(Transport.WebSocket, [ws_endpoint])

    %{initializer: %{version: version}} = wait_for_browser(connection, "chromium")
    browser_guid = browser_from_chromium(connection, version)

    browser = Connection.get(connection, {:guid, browser_guid})
    {connection, browser}
  end

  @doc """
  Launch a new local browser.
  """
  @spec launch() :: {pid(), ChannelOwner.Browser.t()}
  def launch do
    {:ok, connection} = new_session(Transport.Driver, ["assets/node_modules/playwright/lib/cli/cli.js"])
    {connection, chromium(connection)}
  end

  # private
  # ----------------------------------------------------------------------------

  defp chromium(connection) do
    playwright = Connection.get(connection, {:guid, "Playwright"})

    case playwright do
      %ChannelOwner.Playwright{} ->
        %{guid: guid} = playwright.initializer.chromium

        Connection.get(connection, {:guid, guid})
        |> Playwright.ChannelOwner.BrowserType.launch()

      _other ->
        raise("expected chromium to return a Playwright.ChannelOwner.Playwright, received: #{inspect(playwright)}")
    end
  end

  defp new_session(transport, args) do
    DynamicSupervisor.start_child(
      BrowserType.Supervisor,
      {Connection, [{transport, args}]}
    )
  end

  defp wait_for_browser(connection, name) do
    Connection.wait_for_channel_messages(connection, "Browser")
    |> Enum.find(&(&1.initializer.name == name))
  end

  defp browser_from_chromium(connection, version) do
    version = version |> String.split(".") |> Enum.take(3) |> Enum.join(".")

    case Version.compare(version, "90.0.0") do
      :gt ->
        playwright = Connection.get(connection, {:guid, "Playwright"})
        %{guid: guid} = playwright.initializer.preLaunchedBrowser
        guid

      _ ->
        remote_browser = Connection.get(connection, {:guid, "remoteBrowser"})
        %{guid: guid} = remote_browser.initializer.browser
        guid
    end
  end
end
