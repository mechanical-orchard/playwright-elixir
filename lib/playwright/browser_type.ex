defmodule Playwright.BrowserType do
  require Logger

  use Supervisor
  alias Playwright.{Connection}

  # API
  # ---------------------------------------------------------------------------

  defstruct(connection: nil)

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init(args) do
    children = [
      {Connection, args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # private
  # ---------------------------------------------------------------------------
end
