defmodule Playwright.Request do
  @moduledoc false
  use Playwright.Runner.ChannelOwner,
    fields: [:frame, :headers, :is_navigation_request, :method, :post_data, :resource_type, :url]

  alias Playwright.Runner.Connection

  def for_response(response) do
    Connection.get(response.connection, response.initializer.request)
    |> List.first()
  end

  def get_header(subject, name) do
    Enum.find(subject.initializer.headers, fn header ->
      header.name == name
    end)
  end
end
