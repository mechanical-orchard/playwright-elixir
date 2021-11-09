defmodule Playwright.Request do
  @moduledoc false
  use Playwright.Runner.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def for_response(response) do
    Playwright.Runner.Connection.get(response.connection, response.initializer.request)
    |> List.first()
  end

  def get_header(subject, name) do
    Enum.find(subject.initializer.headers, fn header ->
      header.name == name
    end)
  end
end
