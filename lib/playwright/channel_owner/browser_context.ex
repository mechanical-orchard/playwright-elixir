defmodule Playwright.ChannelOwner.BrowserContext do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_page(channel_owner, locals \\ nil) do
    Channel.send(channel_owner, "newPage", %{}, locals)
  end

  def close(channel_owner) do
    channel_owner |> Channel.send("close")
    channel_owner
  end
end
