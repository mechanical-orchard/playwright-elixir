defmodule Playwright.Worker do
  @moduledoc """
  ...
  """
  use Playwright.ChannelOwner

  # @spec expect_event(t(), binary(), function(), options()) :: map()
  # def expect_event(worker, event, predicate \\ nil, options \\ %{})
  # ...delegate wait_for_event -> expect_event
end
