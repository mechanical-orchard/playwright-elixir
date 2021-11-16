defmodule Playwright.Frame do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [:load_states, :url]
  alias Playwright.Frame
  alias Playwright.Runner.{ChannelOwner, EventInfo}

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def before_event(subject, %EventInfo{type: :loadstate, params: params}) do
    case params do
      %{remove: removal} ->
        {:ok, Map.put(subject, :load_states, subject.load_states -- [removal])}

      %{add: addition} ->
        {:ok, Map.put(subject, :load_states, subject.load_states ++ [addition])}
    end
  end

  @impl ChannelOwner
  def before_event(subject, %EventInfo{type: :navigated} = event) do
    {:ok, Map.put(subject, :url, event.params.url)}
  end

  # API
  # ---------------------------------------------------------------------------

  def on(subject, event, handler) do
    Channel.on(subject.connection, {event, subject}, handler)
    subject
  end

  # ???
  def url(f) do
    f.url
  end

  @spec wait_for_load_state(Frame.t(), map()) :: Frame.t()
  def wait_for_load_state(subject, state \\ "load", options \\ %{})

  def wait_for_load_state(subject, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    if Enum.member?(subject.load_states, state) do
      subject
    else
      Channel.wait_for_match(subject, "loadstate", fn event_info ->
        Map.get(event_info.params, :add) == state
      end)

      subject
    end
  end

  def wait_for_load_state(subject, options, _) when is_map(options) do
    wait_for_load_state(subject, "load", options)
  end
end
