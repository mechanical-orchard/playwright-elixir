defmodule Playwright.Server.Playwright do
  # TS: Playwright extends SdkObject
  defstruct(
    chromium: nil,
    firefox: nil,
    webkit: nil,
    selectors: nil
  )

  def new() do
    %__MODULE__{
      # chromium: Chromium.new()
    }
  end
end
