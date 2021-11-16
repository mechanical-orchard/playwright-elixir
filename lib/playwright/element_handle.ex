defmodule Playwright.ElementHandle do
  @moduledoc """
  Defines a handle to a DOM element. `Playwright.ElementHandle` structs may be returned
  from `Playwright.Page` functions such as ` Playwright.Page.query_selector/2`.
  """
  use Playwright.Runner.ChannelOwner, fields: [:preview]
  alias Playwright.ElementHandle
  alias Playwright.Runner.Channel

  @doc """
  Clicks on the given element.
  """
  # @spec click(ElementHandle.t()) :: Channel.Command.t()
  @spec click(ElementHandle.t()) :: nil
  def click(subject) do
    subject |> Channel.send("click")
  end

  def content_frame(handle) do
    handle |> Channel.send("contentFrame")
  end

  @doc """
  Returns the value of an elements attribute, or `nil`.
  """
  @spec get_attribute(ElementHandle.t(), binary()) :: binary() | nil
  def get_attribute(subject, attr_name) do
    subject |> Channel.send("getAttribute", %{name: attr_name})
  end

  @doc """
  Searches within an element for a DOM element matching the given selector.
  """
  @spec query_selector(ElementHandle.t(), binary()) :: ElementHandle.t() | nil
  def query_selector(subject, selector) do
    subject |> Channel.send("querySelector", %{selector: selector})
  end

  @doc """
  Returns all text from an element.
  """
  @spec text_content(ElementHandle.t()) :: binary() | nil
  def text_content(subject) do
    subject |> Channel.send("textContent")
  end
end
