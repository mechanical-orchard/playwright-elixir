defmodule Playwright.Response do
  @moduledoc false
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

  # @spec all_headers(Response.t()) :: {:ok, map()}
  # def all_headers(response)

  # ---

  @spec body(t() | {:ok, t()}) :: {:ok, binary()}
  def body(%Response{} = response) do
    {:ok, result} = Channel.post(response, :body)
    Base.decode64(result)
  end

  def body({:ok, response}) do
    body(response)
  end

  # ---

  # @spec finished(Response.t()) :: :ok | {:error, SomeError.t()}
  # def finished(response)

  # @spec header_value(Response.t(), binary()) :: {:ok, binary() | nil}
  # def header_value(response, name)

  # @spec header_values(Response.t()) :: {:ok, [binary()]}
  # def header_values(response)

  # @spec headers_array(Response.t()) :: {:ok, [map()]}
  # def headers_array(response)

  # @spec json(Response.t()) :: {:ok, Serializable.t()}
  # def json(response)

  # ---

  @spec ok(t() | {:ok, t()}) :: boolean()
  def ok(%Response{} = response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end

  def ok({:ok, response}) do
    ok(response)
  end

  # ---

  # @spec security_details(Response.t()) :: {:ok, map() | nil)}
  # def security_details(response)

  # @spec server_addr(Response.t()) :: {:ok, map() | nil)}
  # def server_addr(response)

  # @spec text(Response.t()) :: {:ok, binary()}
  # def text(response)

  # ---
end
