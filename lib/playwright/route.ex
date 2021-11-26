defmodule Playwright.Route do
  @moduledoc """
  ...
  """
  use Playwright.ChannelOwner
  alias Playwright.Route

  @type options :: map()

  @property :request

  # ---

  # @spec abort(Route.t(), binary()) :: :ok
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

  # ---

  # @spec fulfill(Route.t(), options()) :: :ok
  # def fulfill(route, options \\ %{})

  # @spec request(Route.t()) :: Request.t()
  # def request(route)

  # ---
end
