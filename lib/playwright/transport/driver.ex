defmodule Playwright.Transport.Driver do
  # API
  # ----------------------------------------------------------------------------

  def start_link!([connection | config]) do
    Playwright.Client.Transport.Driver.start_link!(config ++ [connection])
  end

  def post(pid, message) do
    Playwright.Client.Transport.Driver.send_message(pid, message)
  end
end
