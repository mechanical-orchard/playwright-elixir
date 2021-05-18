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
  # # ---------------------------------------------------------------------------

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def connect(ws_endpoint, opts \\ []) do
    {:ok, connection} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Connection, [Transport.WebSocket, [ws_endpoint, opts]]}
      )

    Logger.info("--> Connection...")
    Logger.info("... Started: #{inspect(connection)}")

    # NOTE: this does not (yet) work.
    # {:ok, playwright} = GenServer.call(connection, {:wait_for, "Playwright"})
    # Logger.info("... Playwright: #{inspect(playwright)}")

    # NOTE: for consideration (instead of doing so in the `start_link`)...
    # result = GenServer.call(child, {:connect, [ws_endpoint, opts]})

    {:ok, connection}
  end

  # private
  # ---------------------------------------------------------------------------
end
