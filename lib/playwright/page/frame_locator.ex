defmodule Playwright.Page.FrameLocator do
  @moduledoc """
  FrameLocator represents a view to the iframe on the page.

  It captures the logic sufficient to retrieve the iframe and locate elements in that iframe.
  FrameLocator can be created with either `Page.frame_locator/2` or `Frame.frame_locator/2`.

  ## Examples

      # Locate element inside an iframe
      page
      |> Page.frame_locator("#my-frame")
      |> FrameLocator.get_by_role("button", name: "Submit")
      |> Locator.click()

      # Nested iframes
      page
      |> Page.frame_locator("#outer-frame")
      |> FrameLocator.frame_locator("#inner-frame")
      |> FrameLocator.get_by_text("Hello")
      |> Locator.text_content()
  """

  alias Playwright.{Frame, Locator}

  @enforce_keys [:frame, :selector]
  defstruct [:frame, :selector]

  @type t() :: %__MODULE__{
          frame: Frame.t(),
          selector: binary()
        }

  @doc false
  @spec new(Frame.t(), binary()) :: t()
  def new(%Frame{} = frame, selector) when is_binary(selector) do
    %__MODULE__{frame: frame, selector: selector}
  end

  # ---------------------------------------------------------------------------
  # Chain methods (return FrameLocator)
  # ---------------------------------------------------------------------------

  @doc """
  Returns locator to the first matching frame.
  """
  @spec first(t()) :: t()
  def first(%__MODULE__{} = frame_locator) do
    %{frame_locator | selector: frame_locator.selector <> " >> nth=0"}
  end

  @doc """
  Returns locator to the last matching frame.
  """
  @spec last(t()) :: t()
  def last(%__MODULE__{} = frame_locator) do
    %{frame_locator | selector: frame_locator.selector <> " >> nth=-1"}
  end

  @doc """
  Returns locator to the n-th matching frame (zero-based).
  """
  @spec nth(t(), integer()) :: t()
  def nth(%__MODULE__{} = frame_locator, index) when is_integer(index) do
    %{frame_locator | selector: frame_locator.selector <> " >> nth=#{index}"}
  end

  @doc """
  Returns a FrameLocator for a nested iframe.

  When working with nested iframes, this method allows you to locate iframes
  inside the current frame.
  """
  @spec frame_locator(t(), binary()) :: t()
  def frame_locator(%__MODULE__{} = frame_locator, selector) when is_binary(selector) do
    new_selector = "#{frame_locator.selector} >> internal:control=enter-frame >> #{selector}"
    %{frame_locator | selector: new_selector}
  end

  # ---------------------------------------------------------------------------
  # Locator methods (return Locator)
  # ---------------------------------------------------------------------------

  @doc """
  Returns a Locator for elements matching the selector inside the frame.

  The method finds an element matching the specified selector in the FrameLocator's
  subtree. It also accepts `Locator` as an argument.
  """
  @spec locator(t(), binary() | Locator.t()) :: Locator.t()
  def locator(%__MODULE__{} = frame_locator, selector) when is_binary(selector) do
    full_selector = "#{frame_locator.selector} >> internal:control=enter-frame >> #{selector}"
    Locator.new(frame_locator.frame, full_selector)
  end

  def locator(%__MODULE__{} = frame_locator, %Locator{selector: selector}) do
    locator(frame_locator, selector)
  end

  @doc """
  Returns a Locator pointing to the frame element itself.

  This is useful when you need to interact with the iframe element itself,
  rather than elements inside it.
  """
  @spec owner(t()) :: Locator.t()
  def owner(%__MODULE__{} = frame_locator) do
    Locator.new(frame_locator.frame, frame_locator.selector)
  end

  # ---------------------------------------------------------------------------
  # getBy* methods (return Locator)
  # ---------------------------------------------------------------------------

  @doc """
  Allows locating elements by their alt text.

  ## Options

  - `:exact` - Whether to find an exact match: case-sensitive and whole-string.
    Default: `false`.
  """
  @spec get_by_alt_text(t(), binary(), map()) :: Locator.t()
  def get_by_alt_text(%__MODULE__{} = frame_locator, text, options \\ %{}) when is_binary(text) do
    locator(frame_locator, get_by_attr_selector("alt", text, options))
  end

  @doc """
  Allows locating input elements by their label text.

  ## Options

  - `:exact` - Whether to find an exact match: case-sensitive and whole-string.
    Default: `false`.
  """
  @spec get_by_label(t(), binary(), map()) :: Locator.t()
  def get_by_label(%__MODULE__{} = frame_locator, text, options \\ %{}) when is_binary(text) do
    locator(frame_locator, Locator.get_by_label_selector(text, options))
  end

  @doc """
  Allows locating input elements by their placeholder text.

  ## Options

  - `:exact` - Whether to find an exact match: case-sensitive and whole-string.
    Default: `false`.
  """
  @spec get_by_placeholder(t(), binary(), map()) :: Locator.t()
  def get_by_placeholder(%__MODULE__{} = frame_locator, text, options \\ %{}) when is_binary(text) do
    locator(frame_locator, get_by_attr_selector("placeholder", text, options))
  end

  @doc """
  Allows locating elements by their ARIA role, ARIA attributes and accessible name.

  ## Options

  - `:checked` - An attribute that is usually set by `aria-checked` or native input checkbox.
  - `:disabled` - An attribute that is usually set by `aria-disabled` or `disabled`.
  - `:exact` - Whether `name` is matched exactly: case-sensitive and whole-string.
  - `:expanded` - An attribute that is usually set by `aria-expanded`.
  - `:include_hidden` - Option to match hidden elements.
  - `:level` - A number attribute that is usually present for roles `heading`, `listitem`, etc.
  - `:name` - Option to match the accessible name.
  - `:pressed` - An attribute that is usually set by `aria-pressed`.
  - `:selected` - An attribute that is usually set by `aria-selected`.
  """
  @spec get_by_role(t(), binary(), map()) :: Locator.t()
  def get_by_role(%__MODULE__{} = frame_locator, role, options \\ %{}) when is_binary(role) do
    locator(frame_locator, Locator.get_by_role_selector(role, options))
  end

  @doc """
  Locate element by the test id.

  By default, the `data-testid` attribute is used as a test id.
  """
  @spec get_by_test_id(t(), binary()) :: Locator.t()
  def get_by_test_id(%__MODULE__{} = frame_locator, test_id) when is_binary(test_id) do
    locator(frame_locator, Locator.get_by_test_id_selector(test_id))
  end

  @doc """
  Allows locating elements that contain given text.

  ## Options

  - `:exact` - Whether to find an exact match: case-sensitive and whole-string.
    Default: `false`.
  """
  @spec get_by_text(t(), binary(), map()) :: Locator.t()
  def get_by_text(%__MODULE__{} = frame_locator, text, options \\ %{}) when is_binary(text) do
    locator(frame_locator, Locator.get_by_text_selector(text, options))
  end

  @doc """
  Allows locating elements by their title attribute.

  ## Options

  - `:exact` - Whether to find an exact match: case-sensitive and whole-string.
    Default: `false`.
  """
  @spec get_by_title(t(), binary(), map()) :: Locator.t()
  def get_by_title(%__MODULE__{} = frame_locator, text, options \\ %{}) when is_binary(text) do
    locator(frame_locator, get_by_attr_selector("title", text, options))
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp get_by_attr_selector(attr_name, text, options) do
    exact = Map.get(options, :exact, false)
    escaped = escape_for_attribute_selector(text, exact)
    "internal:attr=[#{attr_name}=#{escaped}]"
  end

  defp escape_for_attribute_selector(value, exact) do
    escaped = value |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"")
    suffix = if exact, do: "s", else: "i"
    "\"#{escaped}\"#{suffix}"
  end
end
