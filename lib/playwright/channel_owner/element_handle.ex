defmodule Playwright.ChannelOwner.ElementHandle do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def text_content(channel_owner) do
    channel_owner |> Channel.send("textContent")
  end
end
