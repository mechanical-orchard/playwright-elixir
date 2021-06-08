defmodule Playwright.ChannelOwner.ElementHandle do
  @moduledoc """
  Defines a handle to a DOM element. ElementHandle structs may be returned
  from Page functions such as `Playwright.ChannelOwner.Page.query_selector/2`.
  """
  use Playwright.ChannelOwner

  @doc false
  def new(parent, args) do
    channel_owner(parent, args)
  end

  @doc """
  Returns the value of an elements attribute, or `nil`.
  """
  @spec get_attribute(t(), binary()) :: binary() | nil
  def get_attribute(channel_owner, attr_name) do
    channel_owner |> Channel.send("getAttribute", %{name: attr_name})
  end

  @doc """
  Returns all text from an element.
  """
  @spec text_content(t()) :: binary() | nil
  def text_content(channel_owner) do
    channel_owner |> Channel.send("textContent")
  end

  @doc """
  Clicks on the given element.
  """
  @spec click(t()) :: boolean()
  def click(channel_owner) do
    channel_owner |> Channel.send("click")
  end
end
