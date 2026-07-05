defmodule Playwright.Tracing do
  @moduledoc """
  Tracing provides methods for recording browser traces.

  Traces can be opened with Playwright Trace Viewer for debugging.

  ## Example

      context = Browser.new_context(browser)
      tracing = BrowserContext.tracing(context)
      Tracing.start(tracing, %{screenshots: true, snapshots: true})
      Page.goto(page, "https://example.com")
      Tracing.stop(tracing, %{path: "trace.zip"})
  """
  use Playwright.SDK.ChannelOwner
  alias Playwright.SDK.Channel

  @doc """
  Start tracing.

  ## Options

  - `:name` - Trace file name prefix
  - `:title` - Trace title shown in viewer
  - `:screenshots` - Capture screenshots (default: false)
  - `:snapshots` - Capture DOM snapshots (default: false)
  """
  @spec start(t(), map()) :: :ok | {:error, term()}
  def start(%__MODULE__{session: session} = tracing, options \\ %{}) do
    params = %{}
    params = if options[:name], do: Map.put(params, :name, options[:name]), else: params
    params = if options[:screenshots], do: Map.put(params, :screenshots, options[:screenshots]), else: params
    params = if options[:snapshots], do: Map.put(params, :snapshots, options[:snapshots]), else: params

    case Channel.post(session, {:guid, tracing.guid}, :tracing_start, params) do
      {:ok, _} -> start_chunk(tracing, options)
      :ok -> start_chunk(tracing, options)
      nil -> start_chunk(tracing, options)
      {:error, _} = error -> error
    end
  end

  @doc """
  Start a new trace chunk.

  ## Options

  - `:name` - Chunk name prefix
  - `:title` - Chunk title in viewer
  """
  @spec start_chunk(t(), map()) :: :ok | {:error, term()}
  def start_chunk(%__MODULE__{session: session} = tracing, options \\ %{}) do
    params = %{}
    params = if options[:name], do: Map.put(params, :name, options[:name]), else: params
    params = if options[:title], do: Map.put(params, :title, options[:title]), else: params

    case Channel.post(session, {:guid, tracing.guid}, :tracing_start_chunk, params) do
      %{traceName: _} -> :ok
      {:ok, _} -> :ok
      :ok -> :ok
      {:error, _} = error -> error
    end
  end

  @doc """
  Stop tracing and export trace.

  ## Options

  - `:path` - File path to save trace zip
  """
  @spec stop(t(), map()) :: :ok | {:error, term()}
  def stop(%__MODULE__{session: session} = tracing, options \\ %{}) do
    stop_chunk(tracing, options)
    Channel.post(session, {:guid, tracing.guid}, :tracing_stop, %{})
    :ok
  end

  @doc """
  Stop current trace chunk and export.

  ## Options

  - `:path` - File path to save trace zip
  """
  @spec stop_chunk(t(), map()) :: :ok | {:error, term()}
  def stop_chunk(%__MODULE__{session: session} = tracing, options \\ %{}) do
    mode = if options[:path], do: "archive", else: "discard"

    case Channel.post(session, {:guid, tracing.guid}, :tracing_stop_chunk, %{mode: mode}) do
      %Playwright.Artifact{} = artifact ->
        if options[:path] do
          Playwright.Artifact.save_as(artifact, options[:path])
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  @doc """
  Creates a named group in the trace.

  Groups help organize actions in the trace viewer.

  ## Options

  - `:location` - Custom location map with `:file`, `:line`, `:column` keys
  """
  @spec group(t(), binary(), map()) :: :ok | {:error, term()}
  def group(%__MODULE__{session: session} = tracing, name, options \\ %{}) do
    params = %{name: name}
    params = if options[:location], do: Map.put(params, :location, options[:location]), else: params

    case Channel.post(session, {:guid, tracing.guid}, :tracing_group, params) do
      {:ok, _} -> :ok
      :ok -> :ok
      nil -> :ok
      {:error, _} = error -> error
    end
  end

  @doc """
  Ends the current group in the trace.
  """
  @spec group_end(t()) :: :ok | {:error, term()}
  def group_end(%__MODULE__{session: session} = tracing) do
    case Channel.post(session, {:guid, tracing.guid}, :tracing_group_end, %{}) do
      {:ok, _} -> :ok
      :ok -> :ok
      nil -> :ok
      {:error, _} = error -> error
    end
  end
end
