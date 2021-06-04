defmodule Playwright do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Playwright.BrowserType.Supervisor}
    ]

    options = [
      name: Playwright.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, options)
  end

  def start() do
    start(nil, nil)
  end
end
