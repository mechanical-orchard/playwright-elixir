defmodule Playwright.Frame do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:url]
  alias Playwright.Runner.Channel
  alias Playwright.Runner.ChannelOwner

  def new(%{connection: _connection} = parent, args) do
    channel_owner(parent, args)
  end

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def before_event(subject, %Channel.Event{type: :navigated} = event) do
    {:ok, Map.put(subject, :url, event.params.url)}
  end

  # API
  # ---------------------------------------------------------------------------

  def url(f) do
    f.url
  end
end
