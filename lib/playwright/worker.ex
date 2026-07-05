defmodule Playwright.Worker do
  @moduledoc """
  The Worker class represents a [WebWorker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API).
  """
  use Playwright.SDK.ChannelOwner

  @property :is_closed
  @property :url

  def init(%{session: session} = worker, _initializer) do
    Channel.bind(session, {:guid, worker.guid}, :close, fn event ->
      {:patch, %{event.target | is_closed: true}}
    end)

    {:ok, worker}
  end

  @doc """
  Registers a callback for the given event.

  Supported events: `:close`, `:console`.
  """
  @spec on(t(), atom(), function()) :: t()
  def on(%{session: session} = worker, event, callback) do
    Channel.bind(session, {:guid, worker.guid}, event, callback)
    worker
  end
end
