defmodule Playwright.Transport.WebSocket do
  alias Playwright.Client.Transport.WebSocket, as: Transport

  # API
  # ----------------------------------------------------------------------------

  def start_link!([connection | config]) do
    Transport.start_link!(config ++ [connection])
  end

  def post(pid, message) do
    Transport.send_message(pid, message)
  end
end
