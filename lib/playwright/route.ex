defmodule Playwright.Route do
  @moduledoc false
  use Playwright.ChannelOwner, fields: [:request]

  def continue(subject) do
    subject
    |> Channel.post(:continue, %{intercept_response: false})
  end
end
