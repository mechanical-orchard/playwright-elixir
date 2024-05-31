defmodule Playwright.Page.Keyboard do
  @moduledoc false

  use Playwright.SDK.ChannelOwner
  alias Playwright.Page

  # API
  # ---------------------------------------------------------------------------

  @spec down(Page.t(), binary()) :: :ok
  def down(page, key) do
    post!(page, :keyboard_down, %{key: key})
  end

  @spec insert_text(Page.t(), binary()) :: :ok
  def insert_text(page, text) do
    post!(page, :keyboard_type, %{text: text})
  end

  @spec press(Page.t(), binary()) :: :ok
  def press(page, key) do
    post!(page, :keyboard_press, %{key: key})
  end

  @spec type(Page.t(), binary()) :: :ok
  def type(page, text) do
    post!(page, :keyboard_type, %{text: text})
  end

  @spec up(Page.t(), binary()) :: :ok
  def up(page, key) do
    post!(page, :keyboard_up, %{key: key})
  end
end
