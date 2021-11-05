defmodule Playwright.Runner.Channel.Response do
  @moduledoc false
  # `Response` represents a message received from the Playwright server that is
  # in response to a `Command` previously sent.
  alias Playwright.Runner.Catalog
  alias Playwright.Runner.Channel.Response

  @enforce_keys [:message, :parsed]
  defstruct [:message, :parsed]

  # @type t() :: %__MODULE__{
  #   parsed: binary()
  # }

  def new(message, catalog) do
    %Response{message: message, parsed: parse(message, catalog)}
  end

  # private
  # ---------------------------------------------------------------------------

  defp parse(%{id: _id, result: result} = _message, catalog) do
    parse(Map.to_list(result), catalog)
  end

  defp parse(%{id: _id} = message, _catalog) do
    message
  end

  defp parse([{_key, %{guid: guid}}], catalog) do
    Catalog.get(catalog, guid)
  end

  # e.g., [rootAXNode: %{children: [%{name: "Hello World", role: "text"}], name: "", role: "WebArea"}],
  defp parse([{_key, %{} = result}], _catalog) do
    result
  end

  defp parse([{:binary, value}], _catalog) do
    value
  end

  defp parse([{:elements, value}], catalog) do
    Enum.map(value, fn %{guid: guid} -> Catalog.get(catalog, guid) end)
  end

  defp parse([{:value, value}], _catalog) do
    value
  end

  defp parse([], _catalog) do
    nil
  end
end
