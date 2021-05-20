defmodule Playwright.ChannelOwner.Page do
  use Playwright.ChannelOwner

  # TODO:
  # - Implement `Channel.send_message`
  #   This is "sort of" underway now, as `send_message` in here
  # - Move all of the "mainFrame" implementations to `Frame`

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def click(channel_owner, selector) do
    channel_send(channel_owner, "click", %{
      selector: selector
    })

    channel_owner
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

  def fill(channel_owner, selector, value) do
    message = %{
      guid: channel_owner.initializer["mainFrame"]["guid"],
      method: "fill",
      params: %{
        selector: selector,
        value: value
      },
      metadata: %{
        apiName: "page.fill"
      }
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

  # NOTE:
  # This one is currently timing out on occasion. Since we return the
  # ChannelOwner, the current workaround is to `press` again.
  def press(channel_owner, selector, key) do
    channel_send(channel_owner, "press", %{
      selector: selector,
      key: key
    })

    channel_owner
  end

  def query_selector(channel_owner, selector) do
    channel_send(channel_owner, "querySelector", %{
      selector: selector
    })
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

  # private
  # ---------------------------------------------------------------------------

  defp channel_send(channel_owner, method, params) do
    message = %{
      guid: channel_owner.initializer["mainFrame"]["guid"],
      method: method,
      params: params
    }

    Connection.post(channel_owner.connection, message)
  end
end
