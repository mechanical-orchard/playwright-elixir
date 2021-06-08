defmodule Playwright.Transport.Driver do
  @moduledoc false
  alias Playwright.Client.Transport.Driver, as: Transport

  # API
  # ----------------------------------------------------------------------------

  def start_link!([connection | config]) do
    Transport.start_link!(config ++ [connection])
  end

  def post(pid, message) do
    Transport.send_message(pid, message)
  end
end
