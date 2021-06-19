defmodule Playwright.BrowserType do
  @moduledoc """
  The `Playwright.BrowserType` module exposes functions that either:

  - launch a new browser instance via a `Port`
  - connect to a running playwright websocket

  ## Examples

  Open a new chromium via the CLI driver:

      {connection, browser} = Playwright.BrowserType.launch()

  Connect to a running playwright instances:

      {connection, browser} = Playwright.BrowserType.connect("ws://localhost:3000/playwright")

  """
  use Playwright.Runner.ChannelOwner

  require Logger

  alias Playwright.BrowserType
  alias Playwright.Runner.Connection
  alias Playwright.Runner.Transport

  def new(parent, args) do
    channel_owner(parent, args)
  end

  @doc """
  Connect to a running playwright server.
  """
  @spec connect(binary()) :: {pid(), Playwright.Browser.t()}
  def connect(ws_endpoint) do
    with {:ok, connection} <- new_session(Transport.WebSocket, [ws_endpoint]),
         %{initializer: %{version: version}} <- wait_for_browser(connection, "chromium"),
         browser_guid <- browser_from_chromium(connection, version),
         browser <- Connection.get(connection, {:guid, browser_guid}) do
      {connection, browser}
    else
      {:error, error} -> {:error, {"Error connecting to #{inspect(ws_endpoint)}", error}}
      error -> {:error, {"Error connecting to #{inspect(ws_endpoint)}", error}}
    end
  end

  @doc """
  Launch a new local browser.
  """
  @spec launch() :: {pid(), Playwright.Browser.t()}
  def launch do
    {:ok, connection} = new_session(Transport.Driver, ["assets/node_modules/playwright/lib/cli/cli.js"])
    {connection, chromium(connection)}
  end

  # private
  # ----------------------------------------------------------------------------

  defp launch(%BrowserType{} = channel_owner) do
    browser = Channel.send(channel_owner, "launch", launch_options())

    case browser do
      %Playwright.Browser{} ->
        browser

      _other ->
        raise("expected launch to return a  Playwright.Browser, received: #{inspect(browser)}")
    end
  end

  defp launch_options do
    Map.merge(
      %{
        args: launch_args(),
        headless: launch_headless?(),
        ignoreAllDefaultArgs: false
      },
      launch_channel()
    )
  end

  defp launch_args do
    Application.get_env(:playwright, :args, [])
  end

  defp launch_channel do
    case Application.get_env(:playwright, :channel, nil) do
      nil ->
        %{}

      channel ->
        %{channel: channel}
    end
  end

  defp launch_headless? do
    Application.get_env(:playwright, :headless, true)
  end

  defp chromium(connection) do
    playwright = Connection.get(connection, {:guid, "Playwright"})

    case playwright do
      %Playwright.Playwright{} ->
        %{guid: guid} = playwright.initializer.chromium

        Connection.get(connection, {:guid, guid}) |> launch()

      _other ->
        raise("expected chromium to return a  Playwright.Playwright, received: #{inspect(playwright)}")
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
