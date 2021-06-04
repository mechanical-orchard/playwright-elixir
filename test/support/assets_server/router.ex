defmodule Test.Support.AssetsServer.Router do
  use Plug.Router

  plug(Plug.Static, at: "/", from: "#{__DIR__}/assets")

  plug(:match)
  plug(:dispatch)

  get("/") do
    send_resp(conn, 200, "Serving Playwright assets")
  end

  match _ do
    send_resp(conn, 404, "404")
  end
end
