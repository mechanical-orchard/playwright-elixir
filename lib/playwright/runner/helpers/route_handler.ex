defmodule Playwright.Runner.Helpers.RouteHandler do
  @moduledoc false

  alias Playwright.Runner.Helpers.URLMatcher

  defstruct([:handler, :matcher, :times])

  def new(matcher, callback) do
    %__MODULE__{
      handler: callback,
      matcher: matcher
    }
  end

  # ---

  def handle(%__MODULE__{handler: handler} = _instance, route, request) do
    Task.start_link(fn ->
      handler.(route, request)
    end)
  end

  def matches(%__MODULE__{} = instance, request_url) do
    URLMatcher.matches(instance.matcher, request_url)
  end
end
