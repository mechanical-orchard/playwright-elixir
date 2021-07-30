defmodule Playwright.Runner.Catalog do
  @moduledoc false
  require Logger
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

  def find(catalog, filter, default \\ nil) do
    case select(values(catalog), filter, []) do
      [] ->
        default
      result ->
        result
    end
  end

  def get(catalog, key) do
    Map.get(catalog.dictionary, key)
  end

  # when is struct...
  def put(catalog, entry) do
    put(catalog, entry.guid, entry)
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

  defp select([], _attrs, result) do
    result
  end

  defp select([head | tail], attrs, result) when head.type == "" do
    select(tail, attrs, result)
  end

  defp select([head | tail], %{parent: parent, type: type} = attrs, result)
       when head.parent.guid == parent.guid and head.type == type do
    select(tail, attrs, result ++ [head])
  end

  defp select([head | tail], %{parent: parent} = attrs, result)
       when head.parent.guid == parent.guid do
    select(tail, attrs, result ++ [head])
  end

  defp select([head | tail], %{type: type} = attrs, result)
       when head.type == type do
    select(tail, attrs, result ++ [head])
  end

  defp select([head | tail], %{guid: guid} = attrs, result)
       when head.guid == guid do
    select(tail, attrs, result ++ [head])
  end

  defp select([_head | tail], attrs, result) do
    select(tail, attrs, result)
  end
end
