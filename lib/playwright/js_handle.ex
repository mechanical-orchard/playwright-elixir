defmodule Playwright.JSHandle do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:preview]

  def as_element(subject) do
    case subject do
      %Playwright.ElementHandle{} = handle ->
        handle

      %Playwright.JSHandle{} ->
        nil
    end
  end
end
