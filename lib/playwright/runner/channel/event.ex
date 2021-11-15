defmodule Playwright.Runner.Channel.Event do
  @moduledoc false
  # `Event` represents a message received from the Playwright server of some
  # action taken related to a resource.
  require Logger
  alias Playwright.Extra
  alias Playwright.Runner.Catalog
  alias Playwright.Runner.ChannelOwner
  alias Playwright.Runner.Helpers

  @enforce_keys [:type]
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

  defp handle(type, %{guid: guid, params: params} = _message, catalog)
       when type in ["close", "navigated"] do
    r = Catalog.get(catalog, guid)
    m = module_for(r)

    {:ok, resource} = m.on_event(r, new(type, params))

    Catalog.put(catalog, resource)
  end

  defp handle(type, %{guid: guid, params: %{message: %{guid: message_guid}}}, catalog)
       when type in ["console"] do
    r = Catalog.get(catalog, guid)
    m = module_for(r)

    message = Catalog.get(catalog, message_guid)
    payload = %{text: message.message_text, type: message.message_type}
    {:ok, resource} = m.on_event(r, new(type, payload))

    Catalog.put(catalog, resource)
  end

  defp handle(type, %{guid: _} = message, catalog)
       when type in ["close"] do
    handle(type, Map.merge(message, %{params: %{}}), catalog)
  end

  defp handle(type, %{guid: guid, params: %{request: %{guid: request_guid}}}, catalog)
       when type in ["request"] do
    r = Catalog.get(catalog, guid)
    m = module_for(r)

    request = Catalog.get(catalog, request_guid)
    payload = %{request: request}
    {:ok, resource} = m.on_event(r, new(type, payload))

    Catalog.put(catalog, resource)
  end

  defp handle(type, %{guid: guid, params: %{request: %{guid: _request_guid}} = params}, catalog)
       when type in ["requestFinished"] do
    r = Catalog.get(catalog, guid)
    m = module_for(r)

    Logger.warn("Event.handle for 'requestFinished' on module: #{inspect(m)}")
    Logger.warn("  --> params: #{inspect(params)}")

    # request = Catalog.get(catalog, request_guid)
    # payload = %{request: request}
    # {:ok, resource} = m.on_event(r, new(type, payload))

    # %{
    #   page: %{guid: "page@0b4c35ea52a2965080a4f678ffbc9d5e"},
    #   request: %{guid: "request@0cc7ee56cc54e29c245929f2de32bc8e"},
    #   response: %{guid: "response@1ed228f031a58d4268a854bd43f6297e"},
    #   responseEndTiming: 24.875
    # }

    payload = Map.merge(params, %{
      page: Catalog.get(catalog, params.page.guid),
      request: Catalog.get(catalog, params.request.guid),
      response: Catalog.get(catalog, params.response.guid)
    })
    {:ok, resource} = m.on_event(r, new(type, payload))

    # %{
    #   "requestFinished" => [#Function<1.1724238/2 in Playwright.Runner.Connection.handle_call/3>]
    # }
    callbacks = (r.waiters[type] || [])
    # |> IO.inspect(label: "FOUND these waiters.........")
    Enum.each(callbacks, fn callback ->
      callback.(resource, payload)
    end)

    resource = %{resource | waiters: Map.put(r.waiters, type, [])}

    Catalog.put(catalog, resource)
  end

  defp handle(type, %{guid: guid, params: %{response: %{guid: response_guid}}}, catalog)
       when type in ["response"] do
    r = Catalog.get(catalog, guid)
    m = module_for(r)

    response = Catalog.get(catalog, response_guid)
    payload = %{response: response}
    {:ok, resource} = m.on_event(r, new(type, payload))

    Catalog.put(catalog, resource)
  end

  # ---

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

  # ---

  defp handle("page", _event, catalog) do
    # Logger.warn("WIP: Event.handle/3 for 'page': event data: #{inspect(event)}")
    catalog
  end

  defp handle("previewUpdated", %{guid: guid, params: params} = _event, catalog) do
    resource = %Playwright.ElementHandle{Catalog.get(catalog, guid) | preview: params.preview}
    Catalog.put(catalog, resource)
  end

  defp handle(method, event, catalog) do
    Logger.debug("Event.handle/3 for unhandled method: #{inspect(method)}; event data: #{inspect(event)}")
    catalog
  end

  defp module_for(resource) do
    String.to_existing_atom("Elixir.Playwright.#{resource.type}")
  end
end
