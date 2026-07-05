defmodule Playwright.Route do
  @moduledoc """
  ...
  """
  use Playwright.SDK.ChannelOwner
  alias Playwright.Route

  @type options :: map()

  @property :request

  # ---

  @doc """
  Aborts the route's request.

  ## Arguments

  | key/name     | type       | description                                      |
  | ------------ | ---------- | ------------------------------------------------ |
  | `error_code` | `binary()` | Optional error code (e.g., "aborted", "failed"). |

  ## Returns

  - `:ok`

  ## Example

      Page.route(page, "**/*.png", fn route, _request ->
        Route.abort(route)
      end)
  """
  @spec abort(t(), binary() | nil) :: :ok
  def abort(%Route{session: session, guid: guid}, error_code \\ nil) do
    params = if error_code, do: %{errorCode: error_code}, else: %{}
    Channel.post(session, {:guid, guid}, :abort, params)
    :ok
  end

  # ---

  @spec continue(t(), options()) :: :ok
  def continue(route, options \\ %{})

  # TODO: figure out what's up with `is_fallback`.
  def continue(%Route{session: session} = route, options) do
    # HACK to deal with changes in v1.33.0
    catalog = Channel.Session.catalog(session)
    request = Channel.Catalog.get(catalog, route.request.guid)
    params = Map.merge(options, %{is_fallback: false, request_url: request.url})
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
