defmodule Playwright.Channel do
  alias Playwright.Connection

  def send(channel_owner, method, params \\ %{}, locals \\ nil) do
    message = %{
      guid: channel_owner.guid,
      method: method,
      params: params,
      locals: locals
    }

    Connection.post(channel_owner.connection, {:data, message})
  end
end
