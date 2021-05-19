defmodule Playwright.ChannelOwner.BrowserType do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_context(channel_owner) do
    message = %{
      guid: channel_owner.guid,
      method: "newContext",
      params: %{sdkLanguage: "javascript", noDefaultViewport: false},
      metadata: %{stack: [], apiName: "browser.newContext"}
    }

    conn = channel_owner.connection
    Connection.post(conn, message)
  end
end
