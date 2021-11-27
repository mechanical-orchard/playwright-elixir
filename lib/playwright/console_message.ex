defmodule Playwright.ConsoleMessage do
  @moduledoc """
  `Playwright.ConsoleMessage` instances are dispatched by page and handled via
  `Playwright.Page.on/3` for the `:console` event type.
  """
  use Playwright.ChannelOwner
  alias Playwright.ChannelOwner

  @property :message_text
  # ... from: :text
  @property :message_type
  # ..., from: :type

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(message, initializer) do
    {:ok, %{message | message_text: initializer.text, message_type: initializer.type}}
  end

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec args(ConsoleMessage.t()) :: [JSHandle.t()]
  # def args(message)

  # @spec location(ConsoleMessage.t()) :: call_location()
  # def location(message)

  # @spec location(ConsoleMessage.t()) :: call_location()
  # def location(message)

  # @spec text(ConsoleMessage.t()) :: String.t()
  # def text(message)

  # @spec type(ConsoleMessage.t()) :: String.t()
  # def type(message)

  # ---
end
