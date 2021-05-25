defmodule Playwright.Client.BrowserType do
  require Logger

  use DynamicSupervisor
  alias Playwright.Client.{Connection, Transport}

  # API
  # ---------------------------------------------------------------------------

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  # # @impl
  # # -------------------------------------------------------------------------

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def connect(ws_endpoint) do
    Logger.info("Connecting to #{inspect(ws_endpoint)}")

    {:ok, connection} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Connection, [Transport.WebSocket, [ws_endpoint]]}
      )

    playwright = Connection.get(connection, "Playwright")
    %{"guid" => guid} = playwright.initializer["preLaunchedBrowser"]
    browser = Connection.get(connection, guid)
    # OR?... browser = Playwright.ChannelOwner.Playwright.chromium()

    {connection, browser}
  end

  def launch(driver_path) do
    {:ok, connection} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Connection, [Transport.Driver, [driver_path]]}
      )

    playwright = Connection.get(connection, "Playwright")
    %{"guid" => guid} = playwright.initializer["chromium"]
    chromium = Connection.get(connection, guid)
    browser = Playwright.ChannelOwner.BrowserType.launch(chromium)

    {connection, browser}
  end

  # private
  # ---------------------------------------------------------------------------
end
