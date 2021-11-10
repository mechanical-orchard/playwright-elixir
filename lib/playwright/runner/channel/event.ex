defmodule Playwright.Runner.Channel.Event do
  @moduledoc false
  # `Event` represents a message received from the Playwright server of some
  # action taken related to a resource.
  require Logger
  alias Playwright.Extra
  alias Playwright.Runner.Catalog
  alias Playwright.Runner.ChannelOwner
  alias Playwright.Runner.Helpers

  @enforce_keys [:type, :params]
  defstruct [:type, :params]

  def new(type, params \\ %{}) do
    %__MODULE__{
      type: Extra.Atom.from_string(type),
      params: params
    }
  end

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

  # ---

  defp handle(type, %{guid: guid, params: params}, catalog)
      when type in ["navigated"] do
    resource = Catalog.get(catalog, guid)
    handlers = resource.listeners[type] || []
    payload = {Extra.Atom.from_string(type), params}

    Enum.each(handlers, fn handler ->
      handler.(resource, payload)
    end)

    catalog
  end

  defp handle(type, %{guid: guid} = _message, catalog)
    when type in ["close"] do
    r = Catalog.get(catalog, guid)
    m = module_for(r)

    {:ok, resource} = m.on_event(r, new(type))

    Catalog.put(catalog, resource)
  end

  # ---

  defp handle("console" = event_type, %{guid: guid, params: %{message: %{guid: message_guid}}}, catalog) do
    resource = Catalog.get(catalog, guid)
    # resource = module(resource).channel__on(resource, event_type)
    handlers = resource.listeners[event_type]

    if handlers do
      message = Catalog.get(catalog, message_guid)
      event = {:on, Extra.Atom.from_string(event_type), message}

      Enum.each(handlers, fn handler ->
        handler.(event)
      end)
    end

    Catalog.put(catalog, resource)
  end

  defp handle("page", _event, catalog) do
    # Logger.warn("WIP: Event.handle/3 for 'page': event data: #{inspect(event)}")
    catalog
  end

  defp handle("previewUpdated", %{guid: guid, params: params} = _event, catalog) do
    resource = %Playwright.ElementHandle{Catalog.get(catalog, guid) | preview: params.preview}
    Catalog.put(catalog, resource)
  end

  defp handle(event_type, %{guid: guid, params: params} = event, catalog)
       when event_type in ["request", "requestFinished"] do
    Logger.debug("WIP: Event.handle/3 for #{inspect(event_type)}, etc.: event: #{inspect(event)}")
    resource = Catalog.get(catalog, guid)
    # resource = module(resource).channel__on(resource, event_type)
    handlers = resource.listeners[event_type]

    # IO.inspect(%{listeners: resource.listeners, resource: resource}, label: "SO FAR")

    type = Extra.Atom.from_string(event_type)

    if handlers do
      request = Catalog.get(catalog, params[:request].guid)
      event = {:on, type, request}

      Enum.each(handlers, fn handler ->
        handler.(event)
      end)
    end

    catalog
  end

  defp handle(event_type, %{guid: guid, params: params} = _event, catalog)
       when event_type in ["response"] do
    # Logger.error("WIP: Event.handle/3 for 'response', etc.: event params: #{inspect(params)}")
    resource = Catalog.get(catalog, guid)
    # resource = module(resource).channel__on(resource, event_type)
    handlers = resource.listeners[event_type]

    type = Extra.Atom.from_string(event_type)

    if handlers do
      response = Catalog.get(catalog, params[:response].guid)
      event = {:on, type, response}

      Enum.each(handlers, fn handler ->
        handler.(event)
      end)
    end

    catalog
  end

  defp handle("route" = event_type, %{guid: guid, params: params} = _event, catalog) do
    resource = Catalog.get(catalog, guid)
    # resource = module(resource).channel__on(resource, event_type)
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

  defp handle(method, event, catalog) do
    Logger.debug("Event.handle/3 for unhandled method: #{inspect(method)}; event data: #{inspect(event)}")
    catalog
  end

  defp module_for(resource) do
    String.to_existing_atom("Elixir.Playwright.#{resource.type}")
  end
end
