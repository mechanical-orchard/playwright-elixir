defmodule Playwright.ChannelOwner.ElementHandle do
  @moduledoc """
  Defines a handle to a DOM element. ElementHandle structs may be returned
  from Page functions such as `Playwright.ChannelOwner.Page.query_selector/2`.
  """
  use Playwright.ChannelOwner
  alias Playwright.ChannelOwner.ElementHandle
  alias Playwright.ChannelMessage

  @doc false
  def new(parent, args) do
    channel_owner(parent, args)
  end

  @doc """
  Clicks on the given element.
  """
  @spec click(ElementHandle.t()) :: ChannelMessage.t()
  def click(channel_owner) do
    channel_owner |> Channel.send("click")
  end

  @doc """
  Returns the value of an elements attribute, or `nil`.
  """
  @spec get_attribute(ElementHandle.t(), binary()) :: binary() | nil
  def get_attribute(channel_owner, attr_name) do
    channel_owner |> Channel.send("getAttribute", %{name: attr_name})
  end

  @doc """
  Searches within an element for a DOM element matching the given selector.
  """
  @spec query_selector(ElementHandle.t(), binary()) :: ElementHandle.t() | nil
  def query_selector(channel_owner, selector) do
    channel_owner |> Channel.send("querySelector", %{selector: selector})
  end

  @doc """
  Returns all text from an element.
  """
  @spec text_content(ElementHandle.t()) :: binary() | nil
  def text_content(channel_owner) do
    channel_owner |> Channel.send("textContent")
  end
end
