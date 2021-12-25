defmodule Playwright.APIResponse do
  @moduledoc false
  use Playwright.ChannelOwner
  alias Playwright.APIResponse

  @property :fetchUid
  @property :headers
  @property :status
  @property :status_text
  @property :url

  @spec ok(t()) :: boolean()
  def ok(%APIResponse{} = response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end
end
