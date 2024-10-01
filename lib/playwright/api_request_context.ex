defmodule Playwright.APIRequestContext do
  @moduledoc """
  This API is used for the Web API testing. You can use it to trigger API
  endpoints, configure micro-services, prepare environment or the server to your
  e2e test.

  Use this at caution as has not been tested.

  """

  use Playwright.SDK.ChannelOwner
  alias Playwright.APIRequestContext
  alias Playwright.SDK.Channel

  # types
  # ----------------------------------------------------------------------------

  @type fetch_options() :: %{
          optional(:params) => any(),
          optional(:method) => binary(),
          optional(:headers) => any(),
          optional(:post_data) => any(),
          optional(:json_data) => any(),
          optional(:form_data) => any(),
          optional(:multipart_data) => any(),
          optional(:timeout) => non_neg_integer(),
          optional(:fail_on_status_code) => boolean(),
          optional(:ignore_HTTPS_errors) => boolean()
        }

  # API
  # ----------------------------------------------------------------------------

  # @spec delete(t(), binary(), options()) :: APIResponse.t()
  # def delete(context, url, options \\ %{})

  # @spec dispose(t()) :: t()
  # def dispose(api_request_context)

  # @spec fetch(t(), binary() | Request.t(), options()) :: APIResponse.t()
  # def fetch(context, url_or_request, options \\ %{})

  # @spec get(t(), binary(), options()) :: APIResponse.t()
  # def get(context, url, options \\ %{})

  # @spec head(t(), binary(), options()) :: APIResponse.t()
  # def head(context, url, options \\ %{})

  # @spec patch(t(), binary(), options()) :: APIResponse.t()
  # def patch(context, url, options \\ %{})

  @spec post(t(), binary(), fetch_options()) :: Playwright.APIResponse.t()
  def post(%APIRequestContext{} = context, url, options \\ %{}) do
    Channel.post({context, :fetch}, %{url: url, method: "POST"}, options)
  end

  # @spec put(t(), binary(), options()) :: APIResponse.t()
  # def put(context, url, options \\ %{})

  # @spec storage_state(t(), options()) :: StorageState.t()
  # def storage_state(context, options \\ %{})

  # TODO: move to `APIResponse.body`, probably.
  @spec body(t(), Playwright.APIResponse.t()) :: any()
  def body(%APIRequestContext{} = context, response) do
    Channel.post({context, :fetch_response_body}, %{fetchUid: response.fetchUid})
  end
end
