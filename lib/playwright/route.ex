defmodule Playwright.Route do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:request]

  def continue(subject) do
    subject
    |> Channel.send("continue", %{interceptResponse: false})
  end
end
