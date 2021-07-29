defmodule Playwright.Runner.Catalog do
  alias Playwright.Runner.Root

  @enforce_keys [:connection, :dictionary]

  defstruct [:connection, :dictionary, :awaiting]

  def new(connection) do
    %__MODULE__{
      connection: connection,
      dictionary: %{
        "Root" => Root.new(connection)
      },
      awaiting: %{}
    }
  end

  # ---

  def await(catalog, key, subscriber) do
    case get(catalog, key) do
      nil ->
        found?(catalog, key, subscriber)
      val ->
        found!(catalog, val, subscriber)
    end
  end

  # ---

  def delete(catalog, key) do
    %__MODULE__{catalog | dictionary: Map.delete(catalog.dictionary, key)}
  end

  def fetch(catalog, key) do
    Map.fetch(catalog.dictionary, key)
  end

  def get(catalog, key) do
    Map.get(catalog.dictionary, key)
  end

  def put(catalog, key, entry) do
    subscriber = Map.get(catalog.awaiting, key)

    if subscriber do
      found!(catalog, entry, subscriber)
    end

    %__MODULE__{catalog | dictionary: Map.put(catalog.dictionary, key, entry)}
  end

  def values(catalog) do
    Map.values(catalog.dictionary)
  end

  # private
  # ---------------------------------------------------------------------------

  defp found?(catalog, key, subscriber) do
    %__MODULE__{catalog | awaiting: Map.put(catalog.awaiting, key, subscriber)}
  end

  defp found!(catalog, entry, subscriber) do
    GenServer.reply(subscriber, entry)
    catalog
  end
end
