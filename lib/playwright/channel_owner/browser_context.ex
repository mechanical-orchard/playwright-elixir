defmodule Playwright.ChannelOwner.BrowserContext do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_page(channel_owner) do
    message = %{
      guid: channel_owner.guid,
      method: "newPage",
      params: %{sdkLanguage: "javascript", noDefaultViewport: false},
      metadata: %{stack: [], apiName: "browserContext.newPage"}
    }

    conn = channel_owner.connection
    %{"result" => %{"page" => page}} = Connection.await_message(conn, message)
    Connection.get_from_guid_map(conn, page["guid"])
  end
end
