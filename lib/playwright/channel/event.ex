defmodule Playwright.Channel.Event do
  @moduledoc false
  alias Playwright.Channel.Catalog
  alias Playwright.Extra

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
        {k, Catalog.get(catalog, guid)}

      {k, v} when is_map(v) ->
        {k, hydrate(v, catalog)}

      {k, l} when is_list(l) ->
        {k, Enum.map(l, fn v -> hydrate(v, catalog) end)}

      {k, v} ->
        {k, v}
    end)
  end
end

# defp module_for(%{__struct__: module}) do
#   module
# end

# defp prepare(%{newDocument: %{request: request}} = params, type, catalog) when type in ["navigated"] do
#   document = %{request: Catalog.get(catalog, request.guid)}
#   Map.put(params, :newDocument, document)
# end

# defp prepare(params, type, catalog) when type in ["page"] do
#   page = Catalog.get(catalog, params.page.guid)
#   frame = Catalog.get(catalog, page.main_frame.guid)

#   Map.merge(params, %{
#     page: page,
#     url: frame.url
#   })
# end

# defp prepare(params, type, _catalog) do
#   Logger.debug("Event.prepare/3 not implemented for type: #{inspect(type)} w/ params: #{inspect(params)}")
#   params
# end
