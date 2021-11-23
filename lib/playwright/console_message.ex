defmodule Playwright.ConsoleMessage do
  @moduledoc """
  `Playwright.ConsoleMessage` instances are dispatched by page and handled via
  `Playwright.Page.on/3` for the `:console` event type.
  """
  use Playwright.ChannelOwner, fields: [:message_text, :message_type]
  alias Playwright.ChannelOwner

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, initializer) do
    {:ok, %{owner | message_text: initializer.text, message_type: initializer.type}}
  end

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec args(ConsoleMessage.t()) :: [JSHandle.t()]
  # def args(owner)

  # @spec location(ConsoleMessage.t()) :: call_location()
  # def location(owner)

  # @spec location(ConsoleMessage.t()) :: call_location()
  # def location(owner)

  # @spec text(ConsoleMessage.t()) :: String.t()
  # def text(owner)

  # @spec type(ConsoleMessage.t()) :: String.t()
  # def type(owner)

  # ---
end
