defmodule Playwright.Channel do
  @moduledoc false
  alias Playwright.ChannelMessage
  alias Playwright.Connection

  def send(channel_owner, method, params \\ %{}, locals \\ nil) do
    message = %ChannelMessage{
      guid: channel_owner.guid,
      id: System.unique_integer([:monotonic, :positive]),
      method: method,
      params: params,
      locals: locals
    }

    Connection.post(channel_owner.connection, {:data, message})
  end
end
