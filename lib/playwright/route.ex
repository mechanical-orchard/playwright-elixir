defmodule Playwright.Route do
  @moduledoc """
  ...
  """
  use Playwright.ChannelOwner
  alias Playwright.Route

  @type options :: map()

  @property :request

  # ---

  # @spec abort(t(), binary()) :: :ok
  # def abort(route, error_code \\ nil)

  # ---

  @spec continue(t() | {:ok, t()}, options()) :: :ok
  def continue(route, options \\ %{})

  def continue(%Route{} = route, options) do
    params = Map.merge(options, %{intercept_response: false})
    {:ok, _} = Channel.post(route, :continue, params)
    :ok
  end

  def continue({:ok, route}, options) do
    continue(route, options)
  end

  @spec fulfill(t(), options()) :: :ok
  # def fulfill(route, options \\ %{})

  def fulfill(route, %{status: status, body: body}) when is_binary(body) do
    length = String.length(body)

    params = %{
      body: body,
      is_base64: false,
      length: length,
      status: status,
      headers:
        serialize_headers(%{
          "content-length" => "#{length}"
        })
    }

    {:ok, _} = Channel.post(route, :fulfill, params)
    :ok
  end

  # ---

  # @spec request(t()) :: Request.t()
  # def request(route)

  # ---

  # private
  # ---------------------------------------------------------------------------

  defp serialize_headers(headers) when is_map(headers) do
    Enum.reduce(headers, [], fn {k, v}, acc ->
      [%{name: k, value: v} | acc]
    end)
  end
end
