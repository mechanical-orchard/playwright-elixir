defmodule Playwright.ChannelOwner.Root do
  @moduledoc """
  Represents the root node of a browser page.
  """
  require Logger
  # TS: Root extends ChannelOwner<channels.Channel>

  defstruct(connection: nil, parent: nil, objects: %{}, type: nil, guid: nil, initializer: nil)

  def new(connection) do
    %__MODULE__{
      connection: connection,
      parent: connection,
      type: "Root",
      guid: "Root",
      initializer: %{}
    }
  end
end
