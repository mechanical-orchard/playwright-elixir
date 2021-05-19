defmodule Playwright.ChannelOwner.Page do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def goto(channel_owner, url) do
    message = %{
      guid: channel_owner.initializer["mainFrame"]["guid"],
      method: "goto",
      params: %{url: url, waitUntil: "load"},
      metadata: %{stack: [], apiName: "page.goto"}
    }

    conn = channel_owner.connection
    result = Connection.await_message(conn, message)
    result
  end
end
