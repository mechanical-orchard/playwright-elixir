defmodule Playwright.SDK.Helpers.WebSocketRouteHandler do
  @moduledoc false

  alias Playwright.SDK.Helpers.{URLMatcher, WebSocketRouteHandler}

  defstruct [:matcher, :callback]

  def new(%URLMatcher{} = matcher, callback) do
    %__MODULE__{
      matcher: matcher,
      callback: callback
    }
  end

  def handle(%WebSocketRouteHandler{callback: callback}, web_socket_route) do
    Task.start(fn ->
      # Run the handler
      callback.(web_socket_route)
      # Ensure the WebSocket is opened even if handler doesn't call connect_to_server
      # This allows sending messages without a real server connection
      Playwright.WebSocketRoute.ensure_opened(web_socket_route)
    end)
  end

  def matches(%WebSocketRouteHandler{matcher: matcher}, url) do
    URLMatcher.matches(matcher, url)
  end

  def prepare(handlers) when is_list(handlers) do
    Enum.into(handlers, [], fn handler ->
      prepare_matcher(handler.matcher)
    end)
  end

  # Private

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
