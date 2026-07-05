defmodule Playwright.WebSocketRouteHandlers do
  @moduledoc false
  # ETS-based storage for WebSocket route handlers and state.
  # Used by WebSocketRoute for message and close event handling.

  alias Playwright.SDK.Channel

  @table :playwright_websocket_route_handlers

  @doc false
  def ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table])

      _ ->
        :ok
    end
  end

  # Page-side handlers

  @doc false
  def set_page_message_handler(guid, handler) do
    ensure_table()
    update_handlers(guid, :page_message, handler)
  end

  @doc false
  def get_page_message_handler(guid) do
    get_handler(guid, :page_message)
  end

  @doc false
  def set_page_close_handler(guid, handler) do
    ensure_table()
    update_handlers(guid, :page_close, handler)
  end

  @doc false
  def get_page_close_handler(guid) do
    get_handler(guid, :page_close)
  end

  # Server-side handlers

  @doc false
  def set_server_message_handler(guid, handler) do
    ensure_table()
    update_handlers(guid, :server_message, handler)
  end

  @doc false
  def get_server_message_handler(guid) do
    get_handler(guid, :server_message)
  end

  @doc false
  def set_server_close_handler(guid, handler) do
    ensure_table()
    update_handlers(guid, :server_close, handler)
  end

  @doc false
  def get_server_close_handler(guid) do
    get_handler(guid, :server_close)
  end

  # Connection state

  @doc false
  def set_connected(guid, session) do
    ensure_table()
    update_handlers(guid, :session, session)
  end

  @doc false
  def forward_to_server(guid, message, is_base64) do
    case get_handler(guid, :session) do
      nil ->
        :ok

      session ->
        Channel.post(session, {:guid, guid}, :send_to_server, %{message: message, isBase64: is_base64})
    end
  end

  # Cleanup

  @doc false
  def cleanup(guid) do
    ensure_table()
    :ets.delete(@table, guid)
  end

  # Private helpers

  defp get_handler(guid, key) do
    ensure_table()

    case :ets.lookup(@table, guid) do
      [{^guid, handlers}] -> Map.get(handlers, key)
      [] -> nil
    end
  end

  defp update_handlers(guid, key, value) do
    ensure_table()

    handlers =
      case :ets.lookup(@table, guid) do
        [{^guid, existing}] -> existing
        [] -> %{}
      end

    :ets.insert(@table, {guid, Map.put(handlers, key, value)})
    :ok
  end
end
