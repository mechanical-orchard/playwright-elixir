defmodule Playwright.SDK.Transport.WebSocket do
  @moduledoc false
  # A transport for negotiating messages with a running Playwright websocket
  # server, built on Mint + Mint.WebSocket.

  defstruct([
    :conn,
    :websocket,
    :ref
  ])

  @connect_timeout 30_000
  @upgrade_timeout 5_000

  # module API
  # ----------------------------------------------------------------------------

  # Mint connection structs are opaque; passing the result of
  # `Mint.HTTP.connect/4` to `Mint.WebSocket.upgrade/4` trips a false-positive
  # `call_with_opaque` warning.
  @dialyzer {:nowarn_function, setup: 1}

  def setup(%{ws_endpoint: ws_endpoint} = config) do
    uri = URI.parse(ws_endpoint)
    {http_scheme, ws_scheme} = schemes(uri)

    # The server pre-launches a browser of this type for the connection.
    browser = Map.get(config, :browser, :chromium)
    headers = [{"x-playwright-browser", to_string(browser)}]

    with {:ok, conn} <-
           Mint.HTTP.connect(http_scheme, uri.host, port(uri),
             protocols: [:http1],
             transport_opts: [timeout: @connect_timeout]
           ),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path(uri), headers),
         {:ok, conn, websocket} <- await_upgrade(conn, ref) do
      %__MODULE__{
        conn: conn,
        websocket: websocket,
        ref: ref
      }
    else
      {:error, reason} -> {:error, reason}
      {:error, _state, reason} -> {:error, reason}
    end
  end

  def post(message, %{conn: conn, websocket: websocket, ref: ref}) do
    case send_frame(conn, websocket, ref, {:text, message}) do
      {:ok, conn, websocket} -> %{conn: conn, websocket: websocket}
      {:error, _reason} -> %{}
    end
  end

  def parse(message, %{conn: conn, websocket: websocket, ref: ref}) do
    case Mint.WebSocket.stream(conn, message) do
      {:ok, conn, responses} ->
        {texts, conn, websocket} = handle_responses(responses, conn, websocket, ref)
        {texts, %{conn: conn, websocket: websocket}}

      {:error, conn, _reason, _responses} ->
        {[], %{conn: conn}}

      :unknown ->
        {[], %{}}
    end
  end

  # private
  # ----------------------------------------------------------------------------

  defp schemes(%{scheme: "ws"}), do: {:http, :ws}
  defp schemes(%{scheme: "wss"}), do: {:https, :wss}

  defp port(%{port: port}) when not is_nil(port), do: port
  defp port(%{scheme: "ws"}), do: 80
  defp port(%{scheme: "wss"}), do: 443

  defp path(%{path: path, query: query}) do
    case {path || "/", query} do
      {path, nil} -> path
      {path, query} -> path <> "?" <> query
    end
  end

  defp await_upgrade(conn, ref, status \\ nil, headers \\ nil) do
    receive do
      message ->
        case Mint.WebSocket.stream(conn, message) do
          {:ok, conn, responses} ->
            resolve_upgrade(responses, conn, ref, status, headers)

          {:error, _conn, reason, _responses} ->
            {:error, reason}

          :unknown ->
            await_upgrade(conn, ref, status, headers)
        end
    after
      @upgrade_timeout ->
        exit(:timeout)
    end
  end

  defp resolve_upgrade([{:status, ref, status} | rest], conn, ref, _status, headers) do
    resolve_upgrade(rest, conn, ref, status, headers)
  end

  defp resolve_upgrade([{:headers, ref, headers} | rest], conn, ref, status, _headers) do
    resolve_upgrade(rest, conn, ref, status, headers)
  end

  defp resolve_upgrade([{:done, ref} | _rest], conn, ref, status, headers) do
    case Mint.WebSocket.new(conn, ref, status, headers) do
      {:ok, conn, websocket} -> {:ok, conn, websocket}
      {:error, _conn, _reason} -> {:error, status}
    end
  end

  defp resolve_upgrade([_response | rest], conn, ref, status, headers) do
    resolve_upgrade(rest, conn, ref, status, headers)
  end

  defp resolve_upgrade([], conn, ref, status, headers) do
    await_upgrade(conn, ref, status, headers)
  end

  defp handle_responses(responses, conn, websocket, ref) do
    Enum.reduce(responses, {[], conn, websocket}, fn
      {:data, ^ref, data}, {texts, conn, websocket} ->
        case Mint.WebSocket.decode(websocket, data) do
          {:ok, websocket, frames} ->
            handle_frames(frames, texts, conn, websocket, ref)

          {:error, websocket, _reason} ->
            {texts, conn, websocket}
        end

      _response, acc ->
        acc
    end)
  end

  defp handle_frames(frames, texts, conn, websocket, ref) do
    Enum.reduce(frames, {texts, conn, websocket}, fn
      {:text, message}, {texts, conn, websocket} ->
        {texts ++ [message], conn, websocket}

      {:ping, data}, {texts, conn, websocket} ->
        case send_frame(conn, websocket, ref, {:pong, data}) do
          {:ok, conn, websocket} -> {texts, conn, websocket}
          {:error, _reason} -> {texts, conn, websocket}
        end

      _frame, acc ->
        acc
    end)
  end

  defp send_frame(conn, websocket, ref, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(websocket, frame),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(conn, ref, data) do
      {:ok, conn, websocket}
    else
      {:error, _state, reason} -> {:error, reason}
    end
  end
end
