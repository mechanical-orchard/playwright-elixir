defmodule Playwright.ChannelOwner.BrowserType do
  @moduledoc false
  use Playwright.ChannelOwner
  alias Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def launch(%ChannelOwner.BrowserType{} = channel_owner) do
    browser = Channel.send(channel_owner, "launch", launch_args())

    case browser do
      %ChannelOwner.Browser{} ->
        browser

      _other ->
        raise("expected launch to return a Playwright.ChannelOwner.Browser, received: #{inspect(browser)}")
    end
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
