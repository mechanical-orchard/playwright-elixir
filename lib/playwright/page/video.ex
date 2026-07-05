defmodule Playwright.Video do
  @moduledoc """
  Video object associated with a page.

  Access video recordings when `record_video` option is enabled in browser context.

  ## Example

      context = Browser.new_context(browser, %{record_video: %{dir: "/tmp/videos"}})
      page = BrowserContext.new_page(context)
      Page.goto(page, "https://example.com")
      Page.close(page)

      video = Page.video(page)
      Video.save_as(video, "recording.webm")
  """

  alias Playwright.Artifact

  @table :playwright_videos

  defstruct [:artifact]

  @type t :: %__MODULE__{artifact: Artifact.t() | nil}

  @doc false
  def ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table])

      _ ->
        :ok
    end
  end

  @doc false
  def store(page_guid, video) do
    ensure_table()
    :ets.insert(@table, {page_guid, video})
  end

  @doc false
  def lookup(page_guid, timeout \\ 2000) do
    ensure_table()
    wait_for_video(page_guid, timeout)
  end

  defp wait_for_video(page_guid, timeout) when timeout <= 0 do
    case :ets.lookup(@table, page_guid) do
      [{^page_guid, video}] -> video
      [] -> nil
    end
  end

  defp wait_for_video(page_guid, timeout) do
    case :ets.lookup(@table, page_guid) do
      [{^page_guid, video}] ->
        video

      [] ->
        Process.sleep(50)
        wait_for_video(page_guid, timeout - 50)
    end
  end

  @doc false
  def delete_entry(page_guid) do
    ensure_table()
    :ets.delete(@table, page_guid)
  end

  @doc """
  Returns the path to the video file.

  Note: Only works for local connections. For remote connections,
  use `save_as/2` to save a copy locally.

  ## Returns

  - `binary()` - The file path
  - `{:error, term()}` - If no video was recorded or remote connection
  """
  @spec path(t()) :: binary() | {:error, term()}
  def path(%__MODULE__{artifact: nil}), do: {:error, "Page did not produce any video frames"}
  def path(%__MODULE__{artifact: artifact}), do: Artifact.path_after_finished(artifact)

  @doc """
  Saves the video to the specified path.

  Safe to call while video is recording or after page closes.
  Works for both local and remote connections.

  ## Returns

  - `:ok`
  - `{:error, term()}` - If no video was recorded
  """
  @spec save_as(t(), binary()) :: :ok | {:error, term()}
  def save_as(%__MODULE__{artifact: nil}, _path), do: {:error, "Page did not produce any video frames"}
  def save_as(%__MODULE__{artifact: artifact}, path), do: Artifact.save_as(artifact, path)

  @doc """
  Deletes the video file.

  ## Returns

  - `:ok`
  - `{:error, term()}` - If deletion fails
  """
  @spec delete(t()) :: :ok | {:error, term()}
  def delete(%__MODULE__{artifact: nil}), do: :ok
  def delete(%__MODULE__{artifact: artifact}), do: Artifact.delete(artifact)

  @doc false
  def new(artifact \\ nil), do: %__MODULE__{artifact: artifact}
end
