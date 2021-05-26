ExUnit.start()

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

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end

defmodule Playwright.Test.Support.AssetsServer.Router do
  use Plug.Router

  plug(Plug.Static, at: "/", from: "#{__DIR__}/support/assets_server/assets")

  plug(:match)
  plug(:dispatch)

  get("/") do
    send_resp(conn, 200, "Serving Playwright assets")
  end

  match _ do
    send_resp(conn, 404, "404")
  end
end
