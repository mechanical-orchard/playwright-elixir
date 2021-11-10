defmodule Playwright.Worker do
  @moduledoc false
  use Playwright.Runner.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def before_event(_, %Channel.Event{type: :close}) do
    nil
  end
end
