defmodule Playwright.Route do
  @moduledoc """
  ...
  """
  use Playwright.SDK.ChannelOwner
  alias Playwright.Route

  @type options :: map()

  @property :request

  # ---

  # @spec abort(t(), binary()) :: :ok
  # def abort(route, error_code \\ nil)

  # ---

  @spec continue(t(), options()) :: :ok
  def continue(route, options \\ %{})

  # TODO: figure out what's up with `is_fallback`.
  def continue(%Route{session: session} = route, options) do
    # HACK to deal with changes in v1.33.0
    catalog = Channel.Session.catalog(session)
    request = Channel.Catalog.get(catalog, route.request.guid)
    Channel.post({route, :continue}, %{is_fallback: false, request_url: request.url}, options)
  end

  # ---

  # @spec fallback(t(), options()) :: :ok
  # def fallback(route, options \\ %{})

  # @spec fetch(t(), options()) :: APIResponse.t()
  # def fetch(route, options \\ %{})

  # ---

  @spec fulfill(t(), options()) :: :ok
  # def fulfill(route, options \\ %{})

  def fulfill(%Route{session: session} = route, %{status: status, body: body}) when is_binary(body) do
    length = String.length(body)

    # HACK to deal with changes in v1.33.0
    catalog = Channel.Session.catalog(session)
    request = Channel.Catalog.get(catalog, route.request.guid)

    params = %{
      body: body,
      is_base64: false,
      length: length,
      request_url: request.url,
      status: status,
      headers:
        serialize_headers(%{
          "content-length" => "#{length}"
        })
    }

    Channel.post({route, :fulfill}, params)
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
