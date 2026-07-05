defmodule Playwright.FileChooser do
  @moduledoc """
  FileChooser instances are dispatched by the page via the `:file_chooser` event.

  ## Example

      Page.on(page, :file_chooser, fn event ->
        file_chooser = FileChooser.from_event(event)
        FileChooser.set_files(file_chooser, "/path/to/file.txt")
      end)

      # Or with expect_event
      event = Page.expect_event(page, :file_chooser, fn ->
        Page.click(page, "input[type=file]")
      end)
      file_chooser = FileChooser.from_event(event)
      FileChooser.set_files(file_chooser, ["/path/to/file1.txt", "/path/to/file2.txt"])
  """

  alias Playwright.ElementHandle

  defstruct [:page, :element, :is_multiple]

  @type t :: %__MODULE__{
          page: Playwright.Page.t(),
          element: ElementHandle.t(),
          is_multiple: boolean()
        }

  @doc false
  def new(page, element, is_multiple) do
    %__MODULE__{
      page: page,
      element: element,
      is_multiple: is_multiple
    }
  end

  @doc """
  Creates a FileChooser from a file_chooser event.

  ## Example

      Page.on(page, :file_chooser, fn event ->
        file_chooser = FileChooser.from_event(event)
        FileChooser.set_files(file_chooser, "/path/to/file.txt")
      end)
  """
  @spec from_event(Playwright.SDK.Channel.Event.t()) :: t()
  def from_event(%{target: page, params: params}) do
    new(page, params.element, params.isMultiple)
  end

  @doc """
  Returns the input element associated with this file chooser.
  """
  @spec element(t()) :: ElementHandle.t()
  def element(%__MODULE__{element: element}), do: element

  @doc """
  Returns whether this file chooser accepts multiple files.
  """
  @spec is_multiple(t()) :: boolean()
  def is_multiple(%__MODULE__{is_multiple: is_multiple}), do: is_multiple

  @doc """
  Returns the page this file chooser belongs to.
  """
  @spec page(t()) :: Playwright.Page.t()
  def page(%__MODULE__{page: page}), do: page

  @doc """
  Sets the value of the file input.

  ## Arguments

  - `files` - Single file path, list of file paths, or file payload map(s)
  - `options` - Optional settings like `:timeout`, `:no_wait_after`

  ## Examples

      FileChooser.set_files(file_chooser, "/path/to/file.txt")
      FileChooser.set_files(file_chooser, ["/path/to/file1.txt", "/path/to/file2.txt"])

      # With file payload
      FileChooser.set_files(file_chooser, %{
        name: "file.txt",
        mimeType: "text/plain",
        buffer: Base.encode64("Hello World")
      })
  """
  @spec set_files(t(), binary() | [binary()] | map() | [map()], map()) :: :ok | {:error, term()}
  def set_files(%__MODULE__{element: element}, files, options \\ %{}) do
    ElementHandle.set_input_files(element, files, options)
  end
end
