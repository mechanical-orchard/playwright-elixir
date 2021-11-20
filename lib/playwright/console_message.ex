defmodule Playwright.ConsoleMessage do
  @moduledoc false
  use Playwright.ChannelOwner, fields: [:message_text, :message_type]
  alias Playwright.ChannelOwner

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, initializer) do
    {:ok, %{owner | message_text: initializer.text, message_type: initializer.type}}
  end
end
