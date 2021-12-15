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

  ## NOTE

  > HTTP error responses, such as 404 or 503, are still successful responses from an HTTP stanpoint. So, such requests
  > will complete with a "requestFinished" event.

  If a request gets a "redirect" response, the request is successfully finished with the "requestFinished" event, and a
  new request is issued to the target redirected URL.
  """
  use Playwright.ChannelOwner
  alias Playwright.Response

  @property :failure
  @property :frame
  @property :headers
  @property :is_navigation_request
  @property :method
  @property :post_data
  @property :post_data_buffer
  @property :post_data_json
  @property :redirected_from
  @property :redirected_to
  @property :resource_type
  @property :timing
  @property :url

  # ---

  # @spec all_headers(Request.t()) :: map()
  # def all_headers(request)

  # @spec header_value(Request.t(), binary()) :: binary() | nil
  # def header_value(request, name)

  # @spec headers_array(Request.t()) :: [map()]
  # def headers_array(request)

  # @spec response(Request.t()) :: Response.t() | nil
  # def response(request)

  # @spec sizes(Request.t()) :: map()
  # def sizes(request)

  # ---

  # NOTE: it might be better to use `Response.request/1`
  @doc false
  def for_response(%Response{} = response) do
    Response.request(response)
  end

  @doc false
  def get_header(request, name) do
    Enum.find(request.initializer.headers, fn header ->
      String.downcase(header.name) == String.downcase(name)
    end)
  end
end
