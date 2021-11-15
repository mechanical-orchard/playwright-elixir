defmodule Playwright.Response do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:status, :url]

  # derived from :initializer
  # ---------------------------------------------------------------------------

  def ok(response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end

  # API call
  # ---------------------------------------------------------------------------

  def body(response) do
    response
    |> Channel.send("body")
    |> Base.decode64!()
  end
end
