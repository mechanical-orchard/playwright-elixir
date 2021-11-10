defmodule Playwright.Frame do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:url]
  alias Playwright.Runner.Channel

  def new(%{connection: connection} = parent, args) do
    instance = channel_owner(parent, args)
    Channel.on(connection, {"navigated", instance}, &handle_event/2)
    instance
  end

  # event callbacks
  # ---------------------------------------------------------------------------

  def handle_event(f, {:navigated, event}) do
    patch(f, %{url: event.url})
  end

  # delegated to :initializer
  # ---------------------------------------------------------------------------

  # delegated to :fields
  # ---------------------------------------------------------------------------

  def url(f) do
    f.url
  end
end

# this._channel.on('navigated', event => {
#   this._url = event.url;
#   this._name = event.name;
#   this._eventEmitter.emit('navigated', event);
#   if (!event.error && this._page)
#     this._page.emit(Events.Page.FrameNavigated, this);
# });

# this._url = initializer.url;
# url(): string {
#   return this._url;
# }
