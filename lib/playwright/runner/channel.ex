defmodule Playwright.Runner.Channel do
  @moduledoc false
  alias Playwright.Runner.ChannelMessage
  alias Playwright.Runner.Connection

  def send(subject, method, params \\ %{}, locals \\ nil) do
    message = %ChannelMessage{
      guid: subject.guid,
      id: System.unique_integer([:monotonic, :positive]),
      method: method,
      params: params,
      locals: locals
    }

    Connection.post(subject.connection, {:data, message})
  end
end
