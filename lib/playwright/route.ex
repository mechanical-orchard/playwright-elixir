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

  @spec continue(t(), options()) :: :ok
  def continue(route, options \\ %{})

  def continue(%Route{session: session} = route, options) do
    # HACK to deal with changes in v1.33.0
    catalog = Playwright.Channel.Session.catalog(session)
    request = Playwright.Channel.Catalog.get(catalog, route.request.guid)
    params = Map.merge(options, %{request_url: request.url})
    Channel.post(session, {:guid, route.guid}, :continue, params)
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
    catalog = Playwright.Channel.Session.catalog(session)
    request = Playwright.Channel.Catalog.get(catalog, route.request.guid)

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

    Channel.post(session, {:guid, route.guid}, :fulfill, params)
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
