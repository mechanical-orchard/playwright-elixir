defmodule Playwright.SDK.Helpers.RouteHandler do
  @moduledoc false

  alias Playwright.SDK.Helpers.{RouteHandler, URLMatcher}

  defstruct([:matcher, :callback, :times, :count])

  def new(%URLMatcher{} = matcher, callback, times \\ :infinity) do
    %__MODULE__{
      matcher: matcher,
      callback: callback,
      times: times,
      count: 0
    }
  end

  # ---

  def matches(%RouteHandler{} = handler, url) do
    URLMatcher.matches(handler.matcher, url)
  end

  def handle(%RouteHandler{} = handler, %{request: request, route: route}) do
    Task.start_link(fn ->
      handler.callback.(route, request)
    end)
  end
end
