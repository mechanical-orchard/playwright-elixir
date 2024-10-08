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
  use Playwright.SDK.ChannelOwner
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

  # @spec failure(Request.t()) :: failure() # map(error_text: message)
  # def failure(request)

  # @spec frame(Request.t()) :: Frame.t()
  # def frame(request)

  # @spec header_value(Request.t(), binary()) :: binary() | nil
  # def header_value(request, name)

  # @spec headers(Request.t()) :: headers() # map()
  # def headers(request)

  # @spec headers_list(Request.t()) :: [map()]
  # def headers_list(request)

  # @spec is_navigation_request(Request.t()) :: boolean()
  # def is_navigation_request(request)

  # @spec method(Request.t()) :: binary()
  # def method(request)

  # @spec post_data(Request.t()) :: binary() | nil
  # def post_data(request)

  # @spec post_data_buffer(Request.t()) :: binary() | nil # Buffer
  # def post_data_buffer(request)

  # @spec post_data_json(Request.t()) :: map() | nil
  # def post_data_json(request)

  # @spec redirected_from(Request.t()) :: Request.t() | nil
  # def redirected_from(request)

  # @spec redirected_to(Request.t()) :: Request.t() | nil
  # def redirected_to(request)

  # @spec resource_type(Request.t()) :: binary()
  # def resource_type(request)

  # @spec response(Request.t()) :: Response.t() | nil
  # def response(request)

  # @spec service_worker(Request.t()) :: Worker.t() | nil
  # def service_worker(request)

  # @spec sizes(Request.t()) :: map()
  # def sizes(request)

  # @spec timing(Request.t()) :: timing()
  # def timing(request)

  # @spec url(Request.t()) :: binary()
  # def url(request)

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
