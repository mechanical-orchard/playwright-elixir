defmodule Playwright.Transport.Driver do
  # API
  # ----------------------------------------------------------------------------

  def start_link!([connection | config]) do
    Playwright.Client.Transport.Driver.start_link!(config ++ [connection])
  end
end
