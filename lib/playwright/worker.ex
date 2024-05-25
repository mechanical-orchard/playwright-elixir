defmodule Playwright.Worker do
  @moduledoc """
  ...
  """
  use Playwright.ChannelOwner

  # @spec evaluate(Worker.t(), function() | binary(), EvaluationArgument.t()) :: Serializable.t()
  # def evaluate(worker, page_function, arg \\ nil)

  # @spec evaluate_handle(Worker.t(), function() | binary(), EvaluationArgument.t()) :: JSHandle.t()
  # def evaluate_handle(worker, page_function, arg \\ nil)

  # @spec expect_event(t(), binary(), function(), options()) :: map()
  # def expect_event(worker, event, predicate \\ nil, options \\ %{})
  # ...delegate wait_for_event -> expect_event

  # on(...):
  #   - close
  # @spec on(t(), binary(), function()) :: nil
  # def on(worker, event, callback)

  # @spec url(Worker.t()) :: binary()
  # def url(worker)
end
