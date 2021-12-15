defmodule Playwright.Response do
  @moduledoc """
  ...
  """
  use Playwright.ChannelOwner
  alias Playwright.Response

  @property :frame
  @property :headers
  @property :request
  @property :status
  @property :status_text
  @property :url

  # API call
  # ---------------------------------------------------------------------------

  # ---

  # @spec all_headers(t()) :: map()
  # def all_headers(response)

  # ---

  @spec body(t()) :: binary()
  def body(%Response{session: session} = response) do
    Channel.post(session, {:guid, response.guid}, :body)
    |> Base.decode64!()
  end

  # ---

  # @spec finished(t()) :: :ok | {:error, SomeError.t()}
  # def finished(response)

  # @spec header_value(t(), binary()) :: binary() | nil
  # def header_value(response, name)

  # @spec header_values(t()) :: [binary()]
  # def header_values(response)

  # @spec headers_array(t()) :: [map()]
  # def headers_array(response)

  # @spec json(t()) :: Serializable.t()
  # def json(response)

  # ---

  @spec ok(t()) :: boolean()
  def ok(%Response{} = response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end

  # ---

  # @spec security_details(t()) :: map() | nil)
  # def security_details(response)

  # @spec server_addr(t()) :: map() | nil)
  # def server_addr(response)

  # ---

  @spec text(t()) :: binary()
  def text(response) do
    body(response)
  end
end
