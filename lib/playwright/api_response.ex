defmodule Playwright.APIResponse do
  @moduledoc false
  use Playwright.SDK.ChannelOwner
  alias Playwright.APIResponse

  @property :fetchUid
  @property :headers
  @property :status
  @property :status_text
  @property :url

  # @spec body(t()) :: binary() # or, equivalent of `Buffer`
  # def body(response)

  # @spec dispose(t()) :: :ok
  # def dispose(response)

  # @spec headers(t()) :: map()
  # def headers(response)

  # @spec headers(t()) :: map()
  # def headers(response)

  # @spec headers_list(APIResponse.t()) :: [map()]
  # def headers_list(response)

  # @spec json(t()) :: binary() # "serializable"; so, maybe map()?
  # def json(response)

  @spec ok(t()) :: boolean()
  def ok(%APIResponse{} = response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end

  # @spec status(t()) :: number()
  # def status(response)

  # @spec status_text(t()) :: binary()
  # def status_text(response)

  # @spec text(t()) :: binary()
  # def text(response)

  # @spec url(t()) :: binary()
  # def url(response)
end
