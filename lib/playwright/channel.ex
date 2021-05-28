defmodule Playwright.Channel do
  alias Playwright.Client.Connection

  def send(channel_owner, method, params \\ %{}) do
    message = %{
      guid: channel_owner.guid,
      method: method,
      params: params
    }

    Connection.post(channel_owner.connection, message)
  end
end
