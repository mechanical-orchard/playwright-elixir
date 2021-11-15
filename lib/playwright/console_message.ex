defmodule Playwright.ConsoleMessage do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:message_text, :message_type]
  alias Playwright.Runner.ChannelOwner

  @impl ChannelOwner
  def new(parent, args) do
    Map.merge(init(parent, args), %{
      message_text: args.initializer.text,
      message_type: args.initializer.type
    })
  end
end
