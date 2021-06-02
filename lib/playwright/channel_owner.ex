defmodule Playwright.ChannelOwner do
  require Logger

  defmacro __using__(_) do
    quote do
      require Logger
      import Playwright.ChannelOwner
      alias Playwright.Channel
      alias Playwright.ChannelOwner.BrowserContext
      alias Playwright.Connection
    end
  end

  # API
  # ---------------------------------------------------------------------------

  defstruct(connection: nil, parent: nil, type: nil, guid: nil, initializer: nil)

  def channel_owner(
        parent,
        %{"guid" => guid, "type" => type, "initializer" => initializer} = _args
      ) do
    %__MODULE__{
      connection: parent.connection,
      parent: parent,
      type: type,
      guid: guid,
      initializer: initializer
    }
  end
end
