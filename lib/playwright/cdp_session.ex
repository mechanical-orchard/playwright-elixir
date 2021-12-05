defmodule Playwright.CDPSession do
  @moduledoc false
  use Playwright.ChannelOwner
  alias Playwright.{CDPSession, ChannelOwner}

  @property :bindings

  @typedoc "Supported events"
  @type event :: binary()

  @typedoc "A map/struct providing call options"
  @type options :: map()

  # Callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%CDPSession{} = session, _initializer) do
    Channel.bind(session, :event, fn %{target: target} = e ->
      handle_event(target, e)
    end)

    {:ok, %{session | bindings: %{}}}
  end

  # API
  # ---------------------------------------------------------------------------

  @spec detach(t()) :: :ok | {:error, term()}
  def detach(%CDPSession{} = session) do
    Channel.post(session, :detach)
  end

  @doc """
  Register a (non-blocking) callback/handler for various types of events.
  """
  @spec on(t(), event(), function()) :: {:ok, CDPSession.t()}
  def on(%CDPSession{bindings: bindings} = session, event, callback) do
    scoped = Map.get(bindings, event, [])
    bindings = Map.put(bindings, event, [callback | scoped])
    Channel.patch(session.connection, session.guid, %{bindings: bindings})
  end

  @spec send(t(), binary(), options()) :: map()
  def send(%CDPSession{} = session, method, params \\ %{}) do
    Channel.post!(session, :send, %{method: method, params: params})
  end

  # private
  # ---------------------------------------------------------------------------

  def handle_event(session, %{params: %{method: method, params: params}}) do
    event = %{
      params: params,
      target: session
    }

    bindings = Map.get(session.bindings, method, [])

    event =
      Enum.reduce(bindings, event, fn callback, acc ->
        case callback.(acc) do
          {:patch, target} ->
            Map.put(acc, :target, target)

          _ok ->
            acc
        end
      end)

    {:ok, event.target}
  end
end
