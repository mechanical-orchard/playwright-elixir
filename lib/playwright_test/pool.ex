defmodule PlaywrightTest.Pool do
  @moduledoc false

  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    pool_args = [
      name: {:local, :playwright},
      worker_module: Playwright.Runner.Connection,
      size: 10,
      max_overflow: 2
    ]

    worker_args = {Playwright.Runner.Transport.Driver, ["assets/node_modules/playwright/cli.js"]}

    case :poolboy.start_link(pool_args, worker_args) do
      {:ok, browser_pool} -> browser_pool
      {:error, {:already_started, browser_pool}} -> browser_pool
    end

    {:ok, %{}}
  end

  def checkout do
    GenServer.call(__MODULE__, {:checkout, self()})
  end

  def handle_call({:checkout, pid}, _from, state) do
    connection = :poolboy.checkout(:playwright)
    browser = Playwright.BrowserType.chromium(connection)

    Process.monitor(pid)
    {:reply, {connection, browser}, Map.put(state, pid, connection)}
  end

  def handle_info({:DOWN, _ref, _type, pid, _reason}, state) do
    {connection, state} = Map.pop(state, pid)
    :poolboy.checkin(:playwright, connection)
    {:noreply, state}
  end
end
