defmodule Playwright.Application do
  @moduledoc false
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      Playwright.SDK.Channel.SessionID,
      {DynamicSupervisor, strategy: :one_for_one, name: Playwright.SDK.Channel.Session.Supervisor}
    ]

    options = [
      name: Playwright.Supervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, options)
  end
end
