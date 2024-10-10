defmodule Playwright.SDK.Channel.Event do
  @moduledoc false
  alias Playwright.SDK.{Channel, Extra}

  @type t() :: %__MODULE__{
          target: struct(),
          type: atom(),
          params: map()
        }

  @enforce_keys [:target, :type]
  defstruct [:target, :type, :params]

  # TODO: consider promoting the params as top-level fields, similarly to how
  # properties are handled in ChannelOwners.
  def new(target, type, params, catalog) do
    %__MODULE__{
      target: target,
      type: as_atom(type),
      params: hydrate(params, catalog)
    }
  end

  # private
  # ---------------------------------------------------------------------------

  defp as_atom(value) when is_atom(value) do
    value
  end

  defp as_atom(value) when is_binary(value) do
    Extra.Atom.snakecased(value)
  end

  defp hydrate(nil, _) do
    nil
  end

  defp hydrate(list, catalog) when is_list(list) do
    Enum.into(list, %{}) |> hydrate(catalog)
  end

  defp hydrate(map, catalog) when is_map(map) do
    Map.new(map, fn
      {k, %{guid: guid}} ->
        {k, Channel.Catalog.get(catalog, guid)}

      {k, v} when is_map(v) ->
        {k, hydrate(v, catalog)}

      {k, l} when is_list(l) ->
        {k, Enum.map(l, fn v -> hydrate(v, catalog) end)}

      {k, v} ->
        {k, v}
    end)
  end
end
