defmodule Playwright.Page.Keyboard do
  @moduledoc """
  `Keyboard` provides an API for managing a virtual keyboard. The high level API
  is `keyboard.type()`, which takes raw characters and generates proper
  `keydown`, `keypress`/`input`, and `keyup` events on your page.

  For finer control, you can use `keyboard.down()`, `keyboard.up()`, and
  `keyboard.insertText()` to manually fire events as if they were generated
  from a real keyboard.

  ## Examples

  ###
  """

  use Playwright.SDK.ChannelOwner
  alias Playwright.Page

  # API
  # ---------------------------------------------------------------------------

  @spec down(Page.t(), binary()) :: Page.t()
  def down(page, key) do
    Channel.post({page, :keyboard_down}, %{key: key})
  end

  @spec insert_text(Page.t(), binary()) :: Page.t()
  def insert_text(page, text) do
    Channel.post({page, :keyboard_type}, %{text: text})
  end

  @spec press(Page.t(), binary()) :: Page.t()
  def press(page, key) do
    Channel.post({page, :keyboard_press}, %{key: key})
  end

  @spec type(Page.t(), binary()) :: Page.t()
  def type(page, text) do
    Channel.post({page, :keyboard_type}, %{text: text})
  end

  @spec up(Page.t(), binary()) :: Page.t()
  def up(page, key) do
    Channel.post({page, :keyboard_up}, %{key: key})
  end
end
