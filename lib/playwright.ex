defmodule Playwright do
  alias Playwright.BrowserType

  def start() do
    {:ok, child} =
      DynamicSupervisor.start_child(
        Playwright.Supervisor,
        {BrowserType,
         [
           "ws://localhost:3000/playwright"
         ]}
      )

    child
  end

  # require Logger

  # alias Playwright.Client

  # def start() do
  #   {:ok, playwright} =
  #     DynamicSupervisor.start_child(Playwright.Supervisor, {
  #       Client,
  #       []
  #     })

  #   playwright
  # end

  # def browser(impl) do
  #   Client.browser(impl)
  # end

  # defmodule Client do
  #   use GenServer

  #   # API
  #   # --------------------------------------------------------------------------

  #   def start_link(args \\ []) do
  #     GenServer.start_link(__MODULE__, args)
  #   end

  #   def browser(self) do
  #     Logger.info("Starting browser for #{inspect(self)}")
  #     GenServer.call(self, {:browser, "ws://localhost:3000/playwright"})
  #   end

  #   # impl
  #   # --------------------------------------------------------------------------

  #   @impl GenServer
  #   def init(args) do
  #     {:ok, args}
  #   end

  #   #
  #   def handle_call({:browser, ws_endpoint}, state) do
  #     browser_type = Playwright.BrowserType.connect(ws_endpoint)
  #     {:reply, browser_type, state}
  #   end
  # end
end
