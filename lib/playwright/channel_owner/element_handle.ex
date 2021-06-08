defmodule Playwright.ChannelOwner.ElementHandle do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def get_attribute(channel_owner, attr_name) do
    channel_owner |> Channel.send("getAttribute", %{name: attr_name})
  end

  def text_content(channel_owner) do
    channel_owner |> Channel.send("textContent")
  end
end
