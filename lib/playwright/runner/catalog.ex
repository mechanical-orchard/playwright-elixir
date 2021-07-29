defmodule Playwright.Runner.Catalog do
  alias Playwright.Runner.Root

  @enforce_keys [:connection, :dictionary]

  defstruct [:connection, :dictionary]

  def new(connection) do
    %__MODULE__{
      connection: connection,
      dictionary: %{
        "Root" => Root.new(connection)
      }
    }
  end

  def delete(catalog, key) do
    %__MODULE__{catalog | dictionary: Map.delete(catalog.dictionary, key)}
  end

  def fetch(catalog, key) do
    Map.fetch(catalog.dictionary, key)
  end

  def get(catalog, key) do
    Map.get(catalog.dictionary, key)
  end

  def put(catalog, key, value) do
    %__MODULE__{catalog | dictionary: Map.put(catalog.dictionary, key, value)}
  end

  def values(catalog) do
    Map.values(catalog.dictionary)
  end
end
