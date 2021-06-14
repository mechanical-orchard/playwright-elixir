defmodule Playwright.BrowserContext do
  @moduledoc false
  use Playwright.Client.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_page(channel_owner, locals \\ nil) do
    Playwright.Client.Channel.send(channel_owner, "newPage", %{}, locals)
  end

  def close(channel_owner) do
    channel_owner |> Playwright.Client.Channel.send("close")
    channel_owner
  end
end
