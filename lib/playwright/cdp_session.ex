defmodule Playwright.CDPSession do
  @moduledoc false
  use Playwright.SDK.ChannelOwner
  alias Playwright.CDPSession
  alias Playwright.SDK.ChannelOwner

  @property :bindings

  @typedoc "An explicit shorthand for the CDPSession.t() subject."
  @type subject :: t()

  @typedoc "Supported events"
  @type event :: binary()

  @typedoc "A map/struct providing call options"
  @type options :: map()

  # Callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(%CDPSession{session: session} = cdp_session, _initializer) do
    Channel.bind(session, {:guid, cdp_session.guid}, :event, fn %{target: target} = e ->
      handle_event(target, e)
    end)

    {:ok, %{cdp_session | bindings: %{}}}
  end

  # API
  # ---------------------------------------------------------------------------

  @spec detach(t()) :: subject() | {:error, term()}
  def detach(%CDPSession{session: session} = cdp_session) do
    case Channel.post(session, {:guid, cdp_session.guid}, :detach) do
      {:ok, _} ->
        cdp_session

      {:error, %Channel.Error{} = error} ->
        {:error, error}
    end
  end

  @doc """
  Register a (non-blocking) callback/handler for various types of events.
  """
  @spec on(t(), event(), function()) :: subject()
  def on(%CDPSession{bindings: bindings, session: session} = cdp_session, event, callback) do
    scoped = Map.get(bindings, event, [])
    bindings = Map.put(bindings, event, [callback | scoped])
    Channel.patch(session, {:guid, cdp_session.guid}, %{bindings: bindings})
  end

  @spec send(t(), binary(), options()) :: map()
  def send(%CDPSession{session: session} = cdp_session, method, params \\ %{}) do
    Channel.post(session, {:guid, cdp_session.guid}, :send, %{method: method, params: params})
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
