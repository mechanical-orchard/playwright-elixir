defmodule Playwright.Runner.Channel.Event do
  @moduledoc false
  # `Event` represents a message received from the Playwright server of some
  # action taken related to a resource.
  require Logger
  alias Playwright.Runner.Catalog
  alias Playwright.Runner.ChannelOwner
  alias Playwright.Runner.EventInfo
  alias Playwright.Runner.Helpers

  def handle(%{method: method} = event, catalog) do
    # IO.inspect(event, label: "Event.handle")
    handle(method, event, catalog)
  end

  # private
  # ---------------------------------------------------------------------------

  # The Playwright server sends back empty string: "" as the parent "guid"
  # for top-level resources. "Root" is nicer, and is how the Root resource
  # is keyed in the Catalog.
  defp handle("__create__", %{guid: ""} = event, catalog) do
    handle("__create__", %{event | guid: "Root"}, catalog)
  end

  # NOTE: there are other `Catalog.put` calls worth considering.
  defp handle("__create__", %{guid: parent, params: params} = _event, catalog) do
    resource = ChannelOwner.from(params, Catalog.get(catalog, parent))
    Catalog.put(catalog, resource)
  end

  # NOTE: assuming that every `Catalog.put`, or similar, has a matching `:guid`, this is complete.
  defp handle("__dispose__", %{guid: guid} = _event, catalog) do
    Catalog.rm_r(catalog, guid)
  end

  # handle: special cases
  # ---------------------------------------------------------------------------

  defp handle("route" = event_type, %{guid: guid, params: params} = _event, catalog) do
    resource = Catalog.get(catalog, guid)
    {handlers, listeners} = Map.pop(resource.listeners, event_type)

    if handlers do
      request = Catalog.get(catalog, params.request.guid)
      route = Catalog.get(catalog, params.route.guid)

      remaining =
        Enum.reduce(handlers, [], fn handler, acc ->
          if Helpers.RouteHandler.matches(handler, request.url) do
            Helpers.RouteHandler.handle(handler, route, request)
            acc
          else
            [handler | acc]
          end
        end)

      Catalog.put(catalog, %{resource | listeners: Map.put(listeners, event_type, remaining)})
    else
      catalog
    end
  end

  defp handle("previewUpdated" = type, %{guid: guid, params: params} = _event, catalog) do
    target = %Playwright.ElementHandle{Catalog.get(catalog, guid) | preview: params.preview}
    module = module_for(target)

    # event_info = EventInfo.new(target, type, prepare(params, type, catalog))
    event_info = EventInfo.new(target, type, params)

    {:ok, target} = module.on_event(target, event_info)
    Catalog.put(catalog, target)
  end

  # handle: general cases
  # ---------------------------------------------------------------------------

  defp handle(type, %{guid: guid, params: params}, catalog)
       when type in ["close", "console", "loadstate", "navigated", "page", "request", "requestFinished", "response"] do
    target = Catalog.get(catalog, guid)
    module = module_for(target)

    event_info = EventInfo.new(target, type, prepare(params, type, catalog))

    {:ok, target} = module.on_event(target, event_info)
    Catalog.put(catalog, target)
  end

  defp handle(type, %{guid: _guid} = message, catalog)
       when type in ["close"] do
    handle(type, Map.merge(message, %{params: %{}}), catalog)
  end

  # to do...
  defp handle(method, event, catalog) do
    Logger.warn("Event.handle/3 for unhandled method: #{inspect(method)}; event data: #{inspect(event)}")
    catalog
  end

  defp module_for(resource) do
    String.to_existing_atom("Elixir.Playwright.#{resource.type}")
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

  defp prepare(%{newDocument: %{request: request}} = params, type, catalog) when type in ["navigated"] do
    document = %{request: Catalog.get(catalog, request.guid)}
    Map.put(params, :newDocument, document)
  end

  defp prepare(params, type, catalog) when type in ["page"] do
    page = Catalog.get(catalog, params.page.guid)
    frame = Catalog.get(catalog, page.main_frame.guid)

    Map.merge(params, %{
      page: page,
      url: frame.url
    })
  end

  defp prepare(params, type, catalog)
       when type in ["close", "console", "loadstate", "request", "navigated", "requestFinished", "response"] do
    hydrate(params, catalog)
  end

  defp prepare(params, type, _catalog) do
    Logger.warn("prepare/3 not implemented for type: #{inspect(type)} w/ params: #{inspect(params)}")
    params
  end
end
