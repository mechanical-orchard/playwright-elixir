defmodule Playwright.ChannelOwner.BrowserType do
  @moduledoc false
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def launch(channel_owner) do
    Channel.send(channel_owner, "launch", launch_args())
  end

  # private
  # ----------------------------------------------------------------------------

  defp launch_args do
    %{
      headless: launch_headless?(),
      ignoreAllDefaultArgs: false
    }
  end

  defp launch_headless? do
    Application.get_env(:playwright, :headless, true)
  end
end
