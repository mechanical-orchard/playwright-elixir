defmodule Playwright.JSHandle do
  @moduledoc false
  use Playwright.ChannelOwner, fields: [:preview]
  alias Playwright.{ElementHandle, JSHandle}

  @doc """
  Returns either `nil` or the object handle itself, if the object handle is an instance of `Playwright.ElementHandle`.
  """
  @spec as_element(struct()) :: ElementHandle.t() | nil
  def as_element(handle)

  def as_element(%ElementHandle{} = handle) do
    handle
  end

  def as_element(%JSHandle{} = _handle) do
    nil
  end

  @doc false
  def as_element({:ok, handle}) do
    as_element(handle)
  end
end
