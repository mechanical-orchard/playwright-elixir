defmodule Playwright.APIRequestContext do
  @moduledoc """
  `Playwright.APIRequestContext` is useful for testing of web APIs.

  The module may be used to trigger API endpoints, configure micro-services,
  prepare environment or services in end-to-end (e2e) tests.

  Each `Playwright.BrowserContext` (browser context) has an associated
  `Playwright.APIRequestContext` (API context) instance that shares cookie
  storage with the browser context and can be accessed via
  `Playwright.BrowserContext.request/1` or `Playwright.Page.request/1`.
  It is also possible to create a new `Playwright.APIRequestContext` instance
  via `Playwright.APIRequest.newContext/2`.

  ## Cookie management

  An `Playwright.APIRequestContext` returned by `Playwright.BrowserContext.request/1`
  or `Playwright.Page.request/1` shares cookie storage with the corresponding
  `Playwright.BrowserContext`. Each API request will have a cookie HTTP header
  populated with the values from the browser context. If the API response
  contains a `Set-Cookie` header, it will automatically update `Playwright.BrowserContext`
  cookies and requests made from the page will pick up the changes. This means
  that if you authenticate using this API, your e2e test will be authenticated.

  If you want API requests to not interfere with the browser cookies, create a
  new `Playwright.APIRequestContext` via `Playwright.APIRequest.new_context/1`.
  Such API contexts will have isolated cookie storage.

  ## Shared options

  The following options are available for all forms of request:

  | name                   |            | description                       |
  | ---------------------- | ---------- | --------------------------------- |
  | `:data`                | (optional) | Sets post data of the request. If the `:data` parameter is a `serializable()`, it will be serialized as a JSON string and the `content-type` HTTP header will be set to `application/json`, if not explicitly set. Otherwise the `content-type` header will be set to `application/octet-stream` if not explicitly set. |
  | `:fail_on_status_code` | (optional) | Whether to raise an error for response codes other than `2xx` and `3xx`. By default, a `Playwright.APIResponse` is returned for all status codes. |
  | `:form`                | (optional) | Provides content that will be serialized as an HTML form using `application/x-www-form-urlencoded` encoding and sent as the request body. If this parameter is specified, the `content-type` HTTP header will be set to `application/x-www-form-urlencoded` unless explicitly provided. |
  | `:headers`             | (optional) | Set HTTP headers. These headers will apply to the fetched request as well as any redirects initiated by it. |
  | `:ignore_https_errors` | (optional) | Whether to ignore HTTPS errors when sending network requests. Defaults to `false`. |
  | `:max_redirects`       | (optional) | Maximum number of request redirects that will be followed automatically. An error will be thrown if the number is exceeded. Defaults to `20`. Pass `0` to not follow redirects. |
  | `:max_retries`         | (optional) | Maximum number of times network errors should be retried. Currently only `ECONNRESET` error is retried. Does not retry based on HTTP response codes. An error will be thrown if the limit is exceeded. Defaults to `0` - no retries. |
  | `:method`              | (optional) | If set changes the fetch method (e.g. [`PUT`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/PUT) or [`POST`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST)). If not specified, [`GET`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET) method is used. |
  | `:multipart`           | (optional) | Provides content that will be serialized as an HTML form using `multipart/form-data` encoding and sent as the request body. If this parameter is specified, the `content-type` header will be set to `multipart/form-data` unless explicitly provided. File values can be passed either as a `Multipart.t()` or as file-like object containing file name, mime-type and content. |
  | `:params`              | (optional) | Query parameters to be sent with the URL. |
  | `:timeout`             | (optional) | Request timeout in milliseconds. Defaults to `30_000` (30 seconds). Pass `0` to disable timeout. |

  When constructing a `:multipart` parameter as a `form()`, the following fields
  should be defined:application

  - `:name` - File name (`String.t()`)
  - `:mime_type` - File type (`String.t()`)
  - `:buffer` - File content (`binary()`)
  """

  use Playwright.SDK.ChannelOwner
  alias Playwright.APIRequestContext
  alias Playwright.APIResponse
  alias Playwright.Request
  alias Playwright.API.Error
  alias Playwright.SDK.Channel

  # types
  # ----------------------------------------------------------------------------

  @typedoc "Options for the various request types."
  @type options :: %{
          # TODO: support the equivalent of TypeScript's `Buffer`
          optional(:data) => serializable() | String.t(),
          optional(:fail_on_status_code) => boolean(),
          optional(:form) => form(),
          optional(:headers) => http_headers(),
          optional(:ignore_https_errors) => boolean(),
          optional(:max_redirects) => number(),
          optional(:max_retries) => number(),
          optional(:method) => String.t(),
          # TODO: support the equivalent of TypeScript's `ReadStream`
          optional(:multipart) => Multipart.t() | form(),
          optional(:params) => form() | String.t(),
          optional(:timeout) => float()
        }

  @typedoc "A data structure for form content."
  @type form :: %{
          required(String.t()) => binary() | boolean() | float() | String.t()
        }

  @typedoc "A `map` containing additional HTTP headers to be sent with every request."
  @type http_headers :: %{required(String.t()) => String.t()}

  @typedoc "Data serializable as JSON."
  @type serializable :: list() | map()

  # API
  # ----------------------------------------------------------------------------

  # @spec delete(t(), binary(), options()) :: APIResponse.t()
  # def delete(context, url, options \\ %{})

  # @spec dispose(t()) :: t()
  # def dispose(api_request_context)

  @doc """
  Sends an HTTP(S) request and returns the response (`Playwright.APIResponse`).

  The function will populate request cookies from the context, and update
  context cookies from the response.

  ## Usage

  JSON objects may be passed directly to the request:

      request = Playwright.request(session)
      context = APIRequest.new_context(request)

      APIRequest.fetch(context, "https://example.com/api/books", %{
        method: "POST",
        data: %{
          author: "Jane Doe",
          title: "Book Title"
        }
      })

  A common way to send file(s) in the body of a request is to upload them as
  form fields with `multipart/form-data` encoding.
  Use [`FormData`](https://developer.mozilla.org/en-US/docs/Web/API/FormData) to
  construct the request body and pass that to the request via the `multipart`
  parameter:

        data = Multipart.new()
          |> Multipart.add_field("author", "Jane Doe")
          |> Multipart.add_field("title", "Book Title")
          |> Multipart.add_file("path/to/manuscript.md", name: "manuscript.md")

        APIRequest.fetch(context, "https://example.com/api/books", %{
          method: "POST",
          multipart: data
        })

  ## Arguments

  | name             |            | description                   |
  | ---------------- | ---------- | ----------------------------- |
  | `url_or_request` |            | The "subject" `APIRequest`    |
  | `options`        | (optional) | `APIRequestContext.options()` |

  ## Options

  See "Shared options" above.
  """
  @spec fetch(t(), binary() | Request.t(), options()) :: APIResponse.t() | {:error, Error.t()}
  def fetch(context, url_or_request, options \\ %{})

  def fetch(%APIRequestContext{} = context, url, options) when is_binary(url) do
    case Channel.post({context, :fetch}, %{url: url, method: "GET"}, options) do
      {:error, _} = error ->
        error

      response ->
        APIResponse.new(Map.merge(response, %{context: context}))
    end
  end

  # @spec get(t(), binary(), options()) :: APIResponse.t()
  # def get(context, url, options \\ %{})

  # @spec head(t(), binary(), options()) :: APIResponse.t()
  # def head(context, url, options \\ %{})

  # @spec patch(t(), binary(), options()) :: APIResponse.t()
  # def patch(context, url, options \\ %{})

  # @spec post(t(), binary(), options()) :: Playwright.APIResponse.t()
  # def post(%APIRequestContext{} = context, url, options \\ %{}) do
  #   Channel.post({context, :fetch}, %{url: url, method: "POST"}, options)
  # end

  # @spec put(t(), binary(), options()) :: APIResponse.t()
  # def put(context, url, options \\ %{})

  # @spec storage_state(t(), options()) :: StorageState.t()
  # def storage_state(context, options \\ %{})
end
