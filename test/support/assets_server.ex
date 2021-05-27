defmodule Playwright.Test.Support.AssetsServer do
  use Application
  alias Playwright.Test.Support.AssetsServer

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

    {:ok, pid} =
      Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
      |> IO.inspect()

    %{
      server: pid,
      prefix: "http://localhost:3002"
    }
  end
end
