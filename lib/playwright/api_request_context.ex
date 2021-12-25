defmodule Playwright.APIRequestContext do
  @moduledoc """
  This API is used for the Web API testing. You can use it to trigger API endpoints, configure micro-services,
  prepare environment or the server to your e2e test.

  Use this at caution as has not been tested.

  """

  use Playwright.ChannelOwner
  alias Playwright.APIRequestContext

  @type fetch_options() :: %{
    optional(:params) => any(),
    optional(:method) => binary(),
    optional(:headers) => any(),
    optional(:postData) => any(),
    optional(:jsonData) => any(),
    optional(:formData) => any(),
    optional(:multipartData) => any(),
    optional(:timeout) => non_neg_integer(),
    optional(:failOnStatusCode) => boolean(),
    optional(:ignoreHTTPSErrors) => boolean()
  }

  @spec post(t(), binary(), fetch_options()) :: Playwright.APIResponse.t()
  def post(%APIRequestContext{} = request_context, url, options \\ %{}) do
    Channel.post(request_context, :fetch, Map.merge(%{
      url: url,
      method: "POST"
    }, options))
  end

  @spec body(t(), Playwright.APIResponse.t()) :: any()
  def body(%APIRequestContext{} = request_context, response) do
    Channel.post(request_context, :fetch_response_body, %{
      fetchUid: response.fetchUid
    })
  end
end
