defmodule Playwright do
  # alias Playwright.BrowserType

  # defdelegate send(browser, message), to: BrowserType
  # defdelegate show(browser), to: BrowserType

  # def connect() do
  #   {:ok, child} =
  #     DynamicSupervisor.start_child(
  #       Playwright.Supervisor,
  #       {BrowserType,
  #        [
  #          "ws://localhost:3000/playwright"
  #        ]}
  #     )

  #   child
  # end

  require Logger

  alias Playwright.Client

  def create() do
    {:ok, playwright} =
      DynamicSupervisor.start_child(Playwright.Supervisor, {
        Client,
        []
      })

    playwright
  end

  def chromium(impl) do
    Client.chromium(impl)
  end

  defmodule Client do
    use GenServer

    # API
    # --------------------------------------------------------------------------

    def start_link(args \\ []) do
      GenServer.start_link(__MODULE__, args)
    end

    def chromium(self) do
      Logger.info("Starting chromium for #{inspect(self)}")
    end

    # impl
    # --------------------------------------------------------------------------

    @impl GenServer
    def init(args) do
      {:ok, args}
    end
  end
end
