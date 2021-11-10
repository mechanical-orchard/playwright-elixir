defmodule Playwright.Route do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:request]

  def new(parent, args) do
    channel_owner(parent, args)
  end

  # ---

  def continue(subject) do
    subject
    |> Channel.send("continue", %{interceptResponse: false})
  end
end
