defmodule Playwright.Runner.Channel.Root do
  @moduledoc false
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
