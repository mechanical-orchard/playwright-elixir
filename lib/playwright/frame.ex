defmodule Playwright.Frame do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:url, :loadstate]
  alias Playwright.Runner.Channel
  alias Playwright.Runner.ChannelOwner

  @impl ChannelOwner
  def new(%{connection: _connection} = parent, args) do
    Map.merge(init(parent, args), %{loadstate: []})
  end

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def before_event(subject, %Channel.Event{type: :navigated} = event) do
    {:ok, Map.put(subject, :url, event.params.url)}
  end

  @impl ChannelOwner
  def before_event(subject, %Channel.Event{type: :loadstate} = event) do
    method = if Map.has_key?(event.params, :add) do
      :add
    else
      :remove
    end

    loadstate = Map.get(subject, :loadstate, [])
    case method do
      :add ->
        {:ok, Map.put(subject, :loadstate, [event.params.add | loadstate])}
      :remove ->
        {:ok, Map.put(subject, :loadstate, Enum.filter(loadstate, fn state -> state != event.params.remove end))}
    end
  end

  # API
  # ---------------------------------------------------------------------------

  def url(f) do
    f.url
  end

  def on(subject, event, handler) do
    Channel.on(subject.connection, {event, subject}, handler)
    subject
  end
end
