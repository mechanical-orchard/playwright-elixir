defmodule PlaywrightTest.Case do
  defmacro __using__(_) do
    quote do
      import Playwright
      alias Playwright.ChannelOwner.Page
    end
  end

  # API
  # ---------------------------------------------------------------------------

  defstruct(connection: nil, parent: nil, type: nil, guid: nil, initializer: nil)

  def playwright do
  end
end
