defmodule Playwright.Runner.Channel.Event do
  @moduledoc false
  # `Event` represents a message received from the Playwright server of some
  # action taken related to a resource.
  alias Playwright.ChannelOwner
  alias Playwright.Runner.{Catalog, EventInfo}
  require Logger

  def handle(%{method: method} = event, catalog, callbacks) when is_list(callbacks) do
    resolve(method, event, catalog, callbacks)
  end

  # private
  # ---------------------------------------------------------------------------

  defp resolve(type, event, catalog, callbacks) do
    case resolve(type, event, catalog) do
      {:ok, %EventInfo{} = event_info} ->
        Enum.each(callbacks, fn callback ->
          callback.(event_info)
        end)

        :ok

      _ ->
        :ok
    end
  end

  # The Playwright server sends back empty string: "" as the parent "guid"
  # for top-level resources. "Root" is nicer, and is how the Root resource
  # is keyed in the Catalog.
  defp resolve("__create__", %{guid: ""} = event, catalog) do
    resolve("__create__", %{event | guid: "Root"}, catalog)
  end

  defp resolve("__create__", %{guid: parent, params: params} = _event, catalog) do
    {:ok, resource} = ChannelOwner.from(params, Catalog.get(catalog, parent))
    Catalog.put(catalog, resource)
  end

  # NOTE: assuming that every `Catalog.put`, or similar, has a matching `:guid`, this is complete.
  defp resolve("__dispose__", %{guid: guid} = _event, catalog) do
    Catalog.rm_r(catalog, guid)
  end

  # resolve: general cases
  # ---------------------------------------------------------------------------

  defp resolve(type, %{guid: guid, params: params}, catalog)
       when type in [
              "close",
              "console",
              "loadState",
              "navigated",
              "page",
              "previewUpdated",
              "request",
              "requestFinished",
              "response",
              "route"
            ] do
    target = Catalog.get(catalog, guid)
    module = module_for(target)
    event_info = EventInfo.new(target, type, prepare(params, type, catalog))

    {:ok, target} = module.on_event(target, event_info)

    Catalog.put(catalog, target)
    {:ok, event_info}
  end

  defp resolve(type, %{guid: _guid} = message, catalog)
       when type in ["close"] do
    resolve(type, Map.merge(message, %{params: %{}}), catalog)
  end

  # to do...
  defp resolve(method, event, catalog) do
    Logger.debug("Event.handle/3 for unhandled method: #{inspect(method)}; event data: #{inspect(event)}")
    catalog
  end

  defp module_for(%{__struct__: module}) do
    module
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
       when type in [
              "close",
              "console",
              "loadState",
              "navigated",
              "previewUpdated",
              "request",
              "requestFinished",
              "response",
              "route"
            ] do
    hydrate(params, catalog)
  end

  defp prepare(params, type, _catalog) do
    Logger.warn("Event.prepare/3 not implemented for type: #{inspect(type)} w/ params: #{inspect(params)}")
    params
  end
end
