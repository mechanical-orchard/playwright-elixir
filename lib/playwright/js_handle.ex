defmodule Playwright.JSHandle do
  @moduledoc false
  use Playwright.Runner.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def as_element(subject) do
    case subject do
      %Playwright.ElementHandle{} = handle ->
        handle

      %Playwright.JSHandle{} ->
        nil
    end
  end
end
