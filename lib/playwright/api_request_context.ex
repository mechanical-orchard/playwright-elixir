defmodule Playwright.APIRequestContext do
  @moduledoc false

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

  @spec post(t(), binary(), fetch_options()) :: t()
  def post(%APIRequestContext{} = request_context, url, options \\ %{}) do
    Channel.post(request_context, :fetch, Map.merge(%{
      url: url,
      method: "POST"
    }, options))
  end

  def body(%APIRequestContext{} = request_context, response) do
    Channel.post(request_context, :fetch_response_body, %{
      fetchUid: response.fetchUid
    })
  end
end
