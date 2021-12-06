defmodule Playwright.WebSocket do
  @moduledoc """
  ...
  """
  use Playwright.ChannelOwner

  @property :is_closed
  @property :url

  # ---

  # @spec expect_event(t(), binary(), function(), options()) :: map()
  # def expect_event(web_socket, event, predicate \\ nil, options \\ %{})
  # ...delegate wait_for_event -> expect_event

  # @spec on(t(), binary(), function()) :: nil
  # def on(web_socket, event, callback)

  # ---
end
