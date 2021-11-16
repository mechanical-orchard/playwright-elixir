defmodule Playwright.Frame do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:url]
  alias Playwright.Runner.ChannelOwner
  alias Playwright.Runner.EventInfo

  @impl ChannelOwner
  def new(%{connection: _connection} = parent, args) do
    init(parent, args)
  end

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def before_event(subject, %EventInfo{type: :navigated} = event) do
    {:ok, Map.put(subject, :url, event.params.url)}
  end

  # API
  # ---------------------------------------------------------------------------

  def on(subject, event, handler) do
    Channel.on(subject.connection, {event, subject}, handler)
    subject
  end

  def url(f) do
    f.url
  end
end
