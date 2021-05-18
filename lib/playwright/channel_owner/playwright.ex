defmodule Playwright.ChannelOwner.Playwright do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  # TODO: consider moving to ChannelOwner, if needed at all.
  # def get(channel_owner, key) do
  #   Logger.info("Getting #{inspect(key)} from channel_owner: #{inspect(channel_owner.initializer)}")
  #   channel_owner.initializer[key]
  # end

  # TODO: consider moving to ChannelOwner, if needed at all.
  # def list(channel_owner) do
  #   Logger.info("Playwright initializer keys: #{inspect(Map.keys(channel_owner.initializer))}")
  #   channel_owner
  # end

  # def chromimum(playwright_channel_owner) do
  #   %{"guid" => guid} = playwright_channel_owner.initializer["chromium"]
  #   GenServer.call(playwright_channel_owner.connection, {:wait_for, guid})
  # end

  # def selectors(playwright_channel_owner) do
  #   playwright_channel_owner.initializer["selectors"]
  # end
end
