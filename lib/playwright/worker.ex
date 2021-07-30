defmodule Playwright.Worker do
  @moduledoc false
  use Playwright.Runner.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  # .channel__on (things that might want to move to Channel)
  # ----------------------------------------------------------------------------

  @doc false
  def channel__on(subject, "close") do
    subject
  end
  # this._channel.on('close', () => {
  #   if (this._page)
  #     this._page._workers.delete(this);
  #   if (this._context)
  #     this._context._serviceWorkers.delete(this);
  #   this.emit(Events.Worker.Close, this);
  # });
end
