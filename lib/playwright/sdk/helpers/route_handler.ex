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

  def handle(%RouteHandler{} = handler, %{request: request, route: route}) do
    Task.start_link(fn ->
      handler.callback.(route, request)
    end)
  end

  def matches(%RouteHandler{} = handler, url) do
    URLMatcher.matches(handler.matcher, url)
  end

  # def prepare([%RouteHandler{}] = handlers) do
  def prepare(handlers) when is_list(handlers) do
    Enum.into(handlers, [], fn handler ->
      prepare_matcher(handler.matcher)
    end)
  end

  # private
  # ----------------------------------------------------------------------------

  defp prepare_matcher(%URLMatcher{match: match}) when is_binary(match) do
    %{glob: match}
  end

  defp prepare_matcher(%URLMatcher{regex: %Regex{} = regex}) do
    %{
      regexSource: Regex.source(regex),
      regexFlags: regex_opts_to_flags(Regex.opts(regex))
    }
  end

  defp regex_opts_to_flags(opts) do
    Enum.map_join(opts, "", fn
      :caseless -> "i"
      :multiline -> "m"
      :dotall -> "s"
      :unicode -> "u"
      _ -> ""
    end)
  end
end
