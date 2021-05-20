defmodule Playwright.ChannelOwner.Page do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def close(channel_owner) do
    message = %{
      guid: channel_owner.guid,
      method: "close",
      params: %{},
      metadata: %{apiName: "page.close"}
    }

    conn = channel_owner.connection
    Connection.post(conn, message)
    channel_owner
  end

  def goto(channel_owner, url) do
    message = %{
      guid: channel_owner.initializer["mainFrame"]["guid"],
      method: "goto",
      params: %{url: url, waitUntil: "load"},
      metadata: %{apiName: "page.goto"}
    }

    conn = channel_owner.connection
    Connection.post(conn, message)
    channel_owner
  end

  def text_content(channel_owner, selector) do
    message = %{
      guid: channel_owner.initializer["mainFrame"]["guid"],
      method: "textContent",
      params: %{selector: selector},
      metadata: %{stack: [], apiName: "page.textContent"}
    }

    conn = channel_owner.connection
    Connection.post(conn, message)
  end

  def title(channel_owner) do
    message = %{
      guid: channel_owner.initializer["mainFrame"]["guid"],
      method: "title",
      metadata: %{
        apiName: "page.title"
      }
    }

    conn = channel_owner.connection
    Connection.post(conn, message)
  end
end
