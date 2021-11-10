defmodule Playwright.ConsoleMessage do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:message_text, :message_type]

  def new(parent, args) do
    Map.merge(channel_owner(parent, args), %{
      message_text: args.initializer.text,
      message_type: args.initializer.type
    })
  end
end
