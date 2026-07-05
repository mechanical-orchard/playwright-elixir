defmodule Playwright.WebSocketRoute do
  @moduledoc """
  Provides methods for handling WebSocket connections during routing.

  When a WebSocket route is set up using `Page.route_web_socket/3` or
  `BrowserContext.route_web_socket/3`, the handler receives a `WebSocketRoute`
  instance that can be used to intercept, modify, or mock WebSocket communication.

  ## Example

      Page.route_web_socket(page, "**/ws", fn ws_route ->
        # Connect to the actual server and proxy messages
        server = WebSocketRoute.connect_to_server(ws_route)

        # Handle messages from the page
        WebSocketRoute.on_message(ws_route, fn message ->
          IO.puts("Page sent: \#{inspect(message)}")
          # Forward to server
          WebSocketRoute.Server.send(server, message)
        end)

        # Handle messages from the server
        WebSocketRoute.Server.on_message(server, fn message ->
          IO.puts("Server sent: \#{inspect(message)}")
          # Forward to page
          WebSocketRoute.send(ws_route, message)
        end)
      end)
  """

  use Playwright.SDK.ChannelOwner

  @property :url

  @typedoc "A WebSocket message, either text (binary) or binary data."
  @type message :: binary()

  @typedoc "A message handler callback."
  @type message_handler :: (message() -> any())

  @typedoc "A close handler callback."
  @type close_handler :: (integer() | nil, binary() | nil -> any())

  @doc """
  Sends a message to the page.

  ## Arguments

  | key/name  | type      | description |
  | --------- | --------- | ----------- |
  | `route`   | `t()`     | The WebSocket route |
  | `message` | `binary()` | Message to send (text or binary) |
  """
  @spec send(t(), message()) :: :ok | {:error, term()}
  def send(%__MODULE__{session: session, guid: guid}, message) do
    {msg, is_base64} = encode_message(message)

    case Channel.post(session, {:guid, guid}, :send_to_page, %{message: msg, isBase64: is_base64}) do
      {:error, _} = error -> error
      _ -> :ok
    end
  end

  @doc """
  Closes the WebSocket connection from the page side.

  ## Options

  | key/name | type      | description |
  | -------- | --------- | ----------- |
  | `:code`  | `integer()` | Close code (default: 1000) |
  | `:reason` | `binary()` | Close reason |
  """
  @spec close(t(), map()) :: :ok | {:error, term()}
  def close(%__MODULE__{session: session, guid: guid}, options \\ %{}) do
    params = %{
      code: options[:code],
      reason: options[:reason],
      wasClean: true
    }

    case Channel.post(session, {:guid, guid}, :close_page, params) do
      {:error, _} = error -> error
      _ -> :ok
    end
  end

  @doc """
  Connects to the actual WebSocket server.

  Returns a `Playwright.WebSocketRoute.Server` struct that can be used to
  interact with the server side of the connection.
  """
  @spec connect_to_server(t()) :: Playwright.WebSocketRoute.Server.t()
  def connect_to_server(%__MODULE__{session: session, guid: guid} = route) do
    Channel.post(session, {:guid, guid}, :connect, %{})
    Playwright.WebSocketRoute.Server.new(route)
  end

  @doc """
  Ensures the WebSocket is open without connecting to the server.

  This allows sending messages to the page even when not connected to a real server.
  """
  @spec ensure_opened(t()) :: :ok | {:error, term()}
  def ensure_opened(%__MODULE__{session: session, guid: guid}) do
    case Channel.post(session, {:guid, guid}, :ensure_opened, %{}) do
      {:error, _} = error -> error
      _ -> :ok
    end
  end

  # Callbacks are stored in ETS for the route handlers
  # See Playwright.WebSocketRouteHandlers module

  @doc """
  Registers a handler for messages received from the page.

  If no handler is set, messages are automatically forwarded to the server
  (if connected via `connect_to_server/1`).
  """
  @spec on_message(t(), message_handler()) :: :ok
  def on_message(%__MODULE__{guid: guid}, handler) when is_function(handler, 1) do
    Playwright.WebSocketRouteHandlers.set_page_message_handler(guid, handler)
  end

  @doc """
  Registers a handler for when the page closes the WebSocket.

  The handler receives the close code and reason.
  """
  @spec on_close(t(), close_handler()) :: :ok
  def on_close(%__MODULE__{guid: guid}, handler) when is_function(handler, 2) do
    Playwright.WebSocketRouteHandlers.set_page_close_handler(guid, handler)
  end

  # ChannelOwner callback
  def init(%__MODULE__{session: session} = route, _initializer) do
    # Bind events for this WebSocket route
    Channel.bind(session, {:guid, route.guid}, :message_from_page, fn %{params: params} ->
      handle_message_from_page(route.guid, params)
      :ok
    end)

    Channel.bind(session, {:guid, route.guid}, :message_from_server, fn %{params: params} ->
      handle_message_from_server(route.guid, params, session)
      :ok
    end)

    Channel.bind(session, {:guid, route.guid}, :close_page, fn %{params: params} ->
      handle_close_page(route.guid, params, session)
      :ok
    end)

    Channel.bind(session, {:guid, route.guid}, :close_server, fn %{params: params} ->
      handle_close_server(route.guid, params, session)
      :ok
    end)

    {:ok, route}
  end

  # Private helpers

  defp encode_message(message) when is_binary(message) do
    if String.valid?(message) do
      {message, false}
    else
      {Base.encode64(message), true}
    end
  end

  defp decode_message(message, true), do: Base.decode64!(message)
  defp decode_message(message, false), do: message

  defp handle_message_from_page(guid, %{message: message, isBase64: is_base64}) do
    decoded = decode_message(message, is_base64)

    case Playwright.WebSocketRouteHandlers.get_page_message_handler(guid) do
      nil ->
        # No handler - auto-forward to server if connected (async to avoid deadlock)
        Task.start(fn ->
          Playwright.WebSocketRouteHandlers.forward_to_server(guid, message, is_base64)
        end)

      handler ->
        Task.start(fn -> handler.(decoded) end)
    end
  end

  defp handle_message_from_server(guid, %{message: message, isBase64: is_base64}, session) do
    decoded = decode_message(message, is_base64)

    case Playwright.WebSocketRouteHandlers.get_server_message_handler(guid) do
      nil ->
        # No handler - auto-forward to page (async to avoid deadlock)
        Task.start(fn ->
          Channel.post(session, {:guid, guid}, :send_to_page, %{message: message, isBase64: is_base64})
        end)

      handler ->
        Task.start(fn -> handler.(decoded) end)
    end
  end

  defp handle_close_page(guid, %{code: code, reason: reason, wasClean: was_clean}, session) do
    case Playwright.WebSocketRouteHandlers.get_page_close_handler(guid) do
      nil ->
        # No handler - auto-forward to server (async to avoid deadlock)
        Task.start(fn ->
          Channel.post(session, {:guid, guid}, :close_server, %{code: code, reason: reason, wasClean: was_clean})
        end)

      handler ->
        Task.start(fn -> handler.(code, reason) end)
    end
  end

  defp handle_close_server(guid, %{code: code, reason: reason, wasClean: was_clean}, session) do
    case Playwright.WebSocketRouteHandlers.get_server_close_handler(guid) do
      nil ->
        # No handler - auto-forward to page (async to avoid deadlock)
        Task.start(fn ->
          Channel.post(session, {:guid, guid}, :close_page, %{code: code, reason: reason, wasClean: was_clean})
        end)

      handler ->
        Task.start(fn -> handler.(code, reason) end)
    end

    # Cleanup handlers when connection closes
    Playwright.WebSocketRouteHandlers.cleanup(guid)
  end
end

defmodule Playwright.WebSocketRoute.Server do
  @moduledoc """
  Represents the server side of a WebSocket route connection.

  Returned by `Playwright.WebSocketRoute.connect_to_server/1`.
  """

  defstruct [:route]

  @type t :: %__MODULE__{route: Playwright.WebSocketRoute.t()}

  @doc false
  def new(route), do: %__MODULE__{route: route}

  @doc """
  Sends a message to the actual WebSocket server.
  """
  @spec send(t(), binary()) :: :ok | {:error, term()}
  def send(%__MODULE__{route: %{session: session, guid: guid}}, message) do
    {msg, is_base64} = encode_message(message)

    case Playwright.SDK.Channel.post(session, {:guid, guid}, :send_to_server, %{
           message: msg,
           isBase64: is_base64
         }) do
      {:error, _} = error -> error
      _ -> :ok
    end
  end

  @doc """
  Closes the connection to the actual WebSocket server.
  """
  @spec close(t(), map()) :: :ok | {:error, term()}
  def close(%__MODULE__{route: %{session: session, guid: guid}}, options \\ %{}) do
    params = %{
      code: options[:code],
      reason: options[:reason],
      wasClean: true
    }

    case Playwright.SDK.Channel.post(session, {:guid, guid}, :close_server, params) do
      {:error, _} = error -> error
      _ -> :ok
    end
  end

  @doc """
  Registers a handler for messages received from the server.
  """
  @spec on_message(t(), Playwright.WebSocketRoute.message_handler()) :: :ok
  def on_message(%__MODULE__{route: %{guid: guid}}, handler) when is_function(handler, 1) do
    Playwright.WebSocketRouteHandlers.set_server_message_handler(guid, handler)
  end

  @doc """
  Registers a handler for when the server closes the WebSocket.
  """
  @spec on_close(t(), Playwright.WebSocketRoute.close_handler()) :: :ok
  def on_close(%__MODULE__{route: %{guid: guid}}, handler) when is_function(handler, 2) do
    Playwright.WebSocketRouteHandlers.set_server_close_handler(guid, handler)
  end

  defp encode_message(message) when is_binary(message) do
    if String.valid?(message) do
      {message, false}
    else
      {Base.encode64(message), true}
    end
  end
end
