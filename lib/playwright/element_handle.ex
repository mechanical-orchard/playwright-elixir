defmodule Playwright.ElementHandle do
  @moduledoc """
  Defines a handle to a DOM element. `Playwright.ElementHandle` structs may be returned
  from `Playwright.Page` functions such as ` Playwright.Page.query_selector/2`.
  """
  use Playwright.ChannelOwner, fields: [:preview]
  alias Playwright.{ChannelOwner, ElementHandle}
  alias Playwright.Runner.{Channel, Helpers}

  @impl ChannelOwner
  def init(%ElementHandle{} = owner, _initializer) do
    Channel.bind(owner, :preview_updated, fn %{params: params} = event ->
      {:patch, %{event.target | preview: params.preview}}
    end)
  end

  @doc """
  Clicks on the given element.
  """
  @spec click(ElementHandle.t()) :: :ok
  def click(%ElementHandle{} = handle) do
    {:ok, _} = Channel.post(handle, :click)
    :ok
  end

  @doc false
  def click({:ok, handle}) do
    click(handle)
  end

  @doc """
  Returns the `Playwright.Frame` for element handles referencing iframe nodes,
  or null otherwise.
  """
  def content_frame(%ElementHandle{} = handle) do
    handle |> Channel.post(:content_frame)
  end

  @doc false
  def content_frame({:ok, handle}) do
    content_frame(handle)
  end

  @doc """
  Returns the value of an elements attribute, or `nil`.
  """
  @spec get_attribute(ElementHandle.t(), binary()) :: {:ok, binary() | nil}
  def get_attribute(handle, attr_name) do
    handle |> Channel.post(:get_attribute, %{name: attr_name})
  end

  def evaluate_handle(handle, expression, arg \\ nil)

  def evaluate_handle(%ElementHandle{} = handle, expression, arg) do
    params = %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    }

    Channel.post(handle, :evaluate_expression_handle, params)
  end

  @doc false
  def evaluate_handle({:ok, handle}, expression, arg) do
    evaluate_handle(handle, expression, arg)
  end

  @doc """
  Searches within an element for a DOM element matching the given selector.
  """
  @spec query_selector(ElementHandle.t(), binary()) :: {:ok, ElementHandle.t() | nil}
  def query_selector(%ElementHandle{} = handle, selector) do
    handle |> Channel.post(:query_selector, %{selector: selector})
  end

  @doc false
  def query_selector({:ok, handle}, selector) do
    query_selector(handle, selector)
  end

  @doc """
  Returns all text from an element.
  """
  @spec text_content(ElementHandle.t()) :: {:ok, binary() | nil}
  def text_content(%ElementHandle{} = handle) do
    handle |> Channel.post(:text_content)
  end

  @doc false
  def text_content({:ok, handle}) do
    text_content(handle)
  end

  @spec is_visible(ElementHandle.t()) :: binary() | nil
  def is_visible(subject) do
    subject |> Channel.send("isVisible")
  end
end
