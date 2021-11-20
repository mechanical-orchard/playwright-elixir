defmodule Playwright.Application do
  @moduledoc false
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      Playwright.ConnectionID,
      {DynamicSupervisor, strategy: :one_for_one, name: Playwright.BrowserType.Supervisor}
    ]

    options = [
      name: Playwright.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, options)
  end
end
