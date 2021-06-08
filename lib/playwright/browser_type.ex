defmodule Playwright.BrowserType do
  @moduledoc false
  alias Playwright.{BrowserType, Connection, Transport}
  require Logger

  # API
  # ----------------------------------------------------------------------------

  def connect(ws_endpoint) do
    {:ok, connection} = new_session(Transport.WebSocket, [ws_endpoint])
    {connection, prelaunched(connection)}
  end

  def launch() do
    {:ok, connection} = new_session(Transport.Driver, ["assets/node_modules/playwright/lib/cli/cli.js"])
    {connection, chromium(connection)}
  end

  # private
  # ----------------------------------------------------------------------------

  defp new_session(transport, args) do
    DynamicSupervisor.start_child(
      BrowserType.Supervisor,
      {Connection, [{transport, args}]}
    )
  end

  defp chromium(connection) do
    playwright = Connection.get(connection, {:guid, "Playwright"})
    %{guid: guid} = playwright.initializer.chromium

    Connection.get(connection, {:guid, guid})
    |> Playwright.ChannelOwner.BrowserType.launch()
  end

  defp prelaunched(connection) do
    playwright = Connection.get(connection, {:guid, "Playwright"})
    %{guid: guid} = playwright.initializer.preLaunchedBrowser

    Connection.get(connection, {:guid, guid})
  end
end
