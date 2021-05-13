defmodule Playwright.ChannelOwner.Browser do
  require Logger

  defstruct(parent: nil, type: nil, guid: nil, initializer: nil)

  def init(connection, parent, type, guid, initializer) do
    Logger.info("Init browser for connection: #{inspect(connection)}")

    %__MODULE__{
      parent: parent,
      type: type,
      guid: guid,
      initializer: initializer
    }
  end
end
