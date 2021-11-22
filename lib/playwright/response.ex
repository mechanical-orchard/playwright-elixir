defmodule Playwright.Response do
  @moduledoc false
  use Playwright.ChannelOwner, fields: [:status, :url, :headers]
  alias Playwright.Response

  # derived from :initializer
  # ---------------------------------------------------------------------------

  @spec ok(Response.t()) :: boolean()
  def ok(%Response{} = response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end

  @doc false
  def ok({:ok, response}) do
    ok(response)
  end

  # API call
  # ---------------------------------------------------------------------------

  @spec body(Response.t()) :: {:ok, binary()}
  def body(%Response{} = response) do
    {:ok, result} = Channel.post(response, :body)
    Base.decode64(result)
  end

  @doc false
  def body({:ok, response}) do
    body(response)
  end
end
