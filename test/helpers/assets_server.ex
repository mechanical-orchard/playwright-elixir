defmodule Playwright.Test.Helpers.AssetsServer do
  use Application
  alias Playwright.Test.Helpers.AssetsServer

  # @impl
  # ----------------------------------------------------------------------------

  @impl Application
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: AssetsServer.Router,
        options: [
          port: 3002,
          ip: {0, 0, 0, 0}
        ]
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
