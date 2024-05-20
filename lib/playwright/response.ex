defmodule Playwright.Response do
  @moduledoc """
  ...
  """
  use Playwright.SDK.ChannelOwner
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

  # @spec frame(Response.t()) :: Frame.t()
  # def frame(response)

  # @spec from_service_worker(Response.t()) :: boolean()
  # def from_service_worker(response)

  # @spec header_value(t(), binary()) :: binary() | nil
  # def header_value(response, name)

  # @spec header_values(t()) :: [binary()]
  # def header_values(response)

  # @spec headers(Response.t()) :: headers() # map()
  # def headers(response)

  # @spec headers_list(Response.t()) :: [map()]
  # def headers_list(response)

  # @spec json(t()) :: Serializable.t()
  # def json(response)

  # ---

  @spec ok(t()) :: boolean()
  def ok(%Response{} = response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end

  @spec ok({t(), t()}) :: boolean()
  def ok({:error, %Playwright.Channel.Error{}}) do
    false
  end

  # ---

  # @spec request(t()) :: Request.t()
  # def request(response)

  # @spec security_details(t()) :: map() | nil
  # def security_details(response)

  # @spec server_addr(t()) :: map() | nil
  # def server_addr(response)

  # @spec status(t()) :: number()
  # def status(response)

  # @spec status_text(t()) :: binary()
  # def status_text(response)

  # ---

  @spec text(t()) :: binary()
  def text(response) do
    body(response)
  end

  # ---

  # @spec url(t()) :: binary()
  # def url(response)

  # ---
end
