defmodule Playwright.Runner.Channel.Event do
  @moduledoc """
  `Event` represents a message received from the Playwright server of some
  action taken related to a resource.
  """
  require Logger
  alias Playwright.Extra
  alias Playwright.Runner.Catalog
  alias Playwright.Runner.ChannelOwner

  @doc """
  Handles an event.
  """
  def handle(%{method: method} = event, catalog) do
    handle(method, event, catalog)
  end

  # private
  # ---------------------------------------------------------------------------

  # move to Catalog?
  defp dispose(guid, catalog) do
    children = Catalog.Server.find(catalog.server, %{parent: Catalog.Server.get(catalog.server, guid)}, [])
    children |> Enum.each(fn child -> dispose(child.guid, catalog) end)

    Catalog.Server.rm(catalog.server, guid)
  end

  # The Playwright server sends back empty string: "" as the parent "guid"
  # for top-level resources. "Root" is nicer, and is how the Root resource
  # is keyed in the Catalog.
  defp handle("__create__", %{guid: ""} = event, catalog) do
    handle("__create__", %{event | guid: "Root"}, catalog)
  end

  defp handle("__create__", %{guid: parent, params: params} = _event, catalog) do
    resource = ChannelOwner.from(params, Catalog.Server.get(catalog.server, parent))
    Catalog.Server.put(catalog.server, resource)
  end

  defp handle("__dispose__", %{guid: guid} = _event, catalog) do
    dispose(guid, catalog)
  end

  defp handle("close" = event_type, %{guid: guid}, catalog) do
    resource = Catalog.Server.get(catalog.server, guid)
    resource = module(resource).channel__on(resource, event_type)
    handlers = resource.listeners[event_type]

    if handlers do
      event = {:on, Extra.Atom.from_string(event_type), resource}

      Enum.each(handlers, fn handler ->
        handler.(event)
      end)
    end

    Catalog.Server.put(catalog.server, resource)
  end

  defp handle("console" = event_type, %{guid: guid, params: %{message: %{guid: message_guid}}}, catalog) do
    resource = Catalog.Server.get(catalog.server, guid)
    resource = module(resource).channel__on(resource, event_type)
    handlers = resource.listeners[event_type]

    if handlers do
      message = Catalog.Server.get(catalog.server, message_guid)
      event = {:on, Extra.Atom.from_string(event_type), message}

      Enum.each(handlers, fn handler ->
        handler.(event)
      end)
    end

    Catalog.Server.put(catalog.server, resource)
  end

  defp handle("previewUpdated", %{guid: guid, params: params} = _event, catalog) do
    resource = %Playwright.ElementHandle{Catalog.Server.get(catalog.server, guid) | preview: params.preview}
    Catalog.Server.put(catalog.server, resource)
  end

  defp handle(_method, _event, catalog) do
    # Logger.warn("Event.handle/3 for unhandled method: #{inspect(method)}; event data: #{inspect(event)}")
    catalog
  end

  defp module(resource) do
    String.to_existing_atom("Elixir.Playwright.#{resource.type}")
  end
end
