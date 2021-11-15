# THIS(+1)
defmodule Playwright.Request do
  @moduledoc """
  `Playwright.Request` represents a request for a network resource.

  Whenever the page sends a request for a network resource, the following sequence of events are emitted by
  `Playwright.Page`:

  - `Playwright.Page.on/3` for "request":
    emitted when the request is issued by the page.
  - `Playwright.Page.on/3` for "response":
    emitted when/if the response status and headers are received for the request.
  - `Playwright.Page.on/3` for "requestFinished":
    emitted when the response body is downloaded and the request is complete.

  If the request fails at some point, instead of a "requestFinished" event (and possibly "response" as well),
  the `Playwright.Page.on/3` for "requestFailed" is emitted.

  > NOTE
  > HTTP error responses, such as 404 or 503, are still successful responses from an HTTP stanpoint. So, such requests
  > will complete with a "requestFinished" event.

  If a request gets a "redirect" response, the request is successfully finished with the "requestFinished" event, and a
  new request is issued to the target redirected URL.
  """
  use Playwright.Runner.ChannelOwner,
    fields: [:frame, :headers, :is_navigation_request, :method, :post_data, :resource_type, :url]

  alias Playwright.Runner.Connection

  # ---

  # def all_headers(request) do
  # end

  # ---

  # NOTE: it might be better to use `Response.request/1`
  @doc false
  def for_response(response) do
    Connection.get(response.connection, response.initializer.request)
    |> List.first()
  end

  @doc false
  def get_header(subject, name) do
    Enum.find(subject.initializer.headers, fn header ->
      header.name == name
    end)
  end
end
