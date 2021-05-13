defmodule Playwright.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Playwright.Supervisor}
    ]

    options = [
      name: __MODULE__,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, options)
  end
end
