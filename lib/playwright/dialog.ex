defmodule Playwright.Dialog do
  @moduledoc """
  `Playwright.Dialog` instances are dispatched by page and handled via
  `Playwright.Page.on/3` for the `:dialog` event type.

  ## Dialog Types

  - `"alert"` - Alert dialog with OK button
  - `"confirm"` - Confirm dialog with OK and Cancel buttons
  - `"prompt"` - Prompt dialog with text input
  - `"beforeunload"` - Before unload dialog

  ## Example

      Page.on(page, :dialog, fn dialog ->
        IO.puts("Dialog message: \#{Dialog.message(dialog)}")
        Dialog.accept(dialog)
      end)

      # For prompts with input:
      Page.on(page, :dialog, fn dialog ->
        Dialog.accept(dialog, "my input")
      end)
  """
  use Playwright.SDK.ChannelOwner
  alias Playwright.SDK.{Channel, ChannelOwner}

  @property :default_value
  @property :message
  @property :dialog_type

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(dialog, initializer) do
    {:ok,
     %{
       dialog
       | default_value: initializer.default_value,
         message: initializer.message,
         dialog_type: initializer.type
     }}
  end

  @doc """
  Get the dialog type.

  Returns one of: `"alert"`, `"confirm"`, `"prompt"`, `"beforeunload"`.
  """
  @spec type(t()) :: binary()
  def type(dialog) do
    dialog_type(dialog)
  end

  # API
  # ---------------------------------------------------------------------------

  @doc """
  Accept the dialog.

  For prompt dialogs, optionally provide text input.

  ## Arguments

  - `prompt_text` - Text to enter in prompt dialog (optional)

  ## Examples

      Dialog.accept(dialog)
      Dialog.accept(dialog, "my input")
  """
  @spec accept(t(), binary() | nil) :: :ok
  def accept(dialog, prompt_text \\ nil)

  def accept(%__MODULE__{session: session} = dialog, nil) do
    Channel.post(session, {:guid, dialog.guid}, :accept, %{})
    :ok
  end

  def accept(%__MODULE__{session: session} = dialog, prompt_text) when is_binary(prompt_text) do
    Channel.post(session, {:guid, dialog.guid}, :accept, %{promptText: prompt_text})
    :ok
  end

  @doc """
  Dismiss the dialog (click Cancel or close).
  """
  @spec dismiss(t()) :: :ok
  def dismiss(%__MODULE__{session: session} = dialog) do
    Channel.post(session, {:guid, dialog.guid}, :dismiss, %{})
    :ok
  end

  @doc """
  Get the page that initiated the dialog.

  Returns `nil` if dialog was triggered by a different context.
  """
  @spec page(t()) :: Playwright.Page.t() | nil
  def page(%__MODULE__{session: session, parent: parent}) do
    case parent do
      %{guid: guid} -> Channel.find(session, {:guid, guid})
      _ -> nil
    end
  end
end
