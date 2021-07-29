defmodule Playwright.Runner.Callback do
  @moduledoc false
  require Logger

  defstruct [:listener, :message]

  def new(listener, message) do
    %__MODULE__{
      listener: listener,
      message: message
    }
  end

  # def resolve(%{listener: listener, message: message}, resource) do
  #   Logger.warn("Callback...")
  #   Logger.warn("  - listener: #{inspect(listener)}")
  #   Logger.warn("  - message: #{inspect(message)}")
  #   Logger.warn("  - resource: #{inspect(resource)}")
  def resolve(%{listener: listener}, resource) do
    GenServer.reply(listener, resource)
  end
end
