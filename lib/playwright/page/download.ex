defmodule Playwright.Download do
  @moduledoc """
  Download objects are dispatched by page via the `:download` event.

  ## Example

      Page.on(page, :download, fn download ->
        Download.save_as(download, "/tmp/my-file.pdf")
      end)
  """

  alias Playwright.Artifact

  defstruct [:url, :suggested_filename, :page, :artifact]

  @type t :: %__MODULE__{
          url: binary(),
          suggested_filename: binary(),
          page: Playwright.Page.t(),
          artifact: Artifact.t()
        }

  @doc false
  def new(page, url, suggested_filename, artifact) do
    %__MODULE__{
      url: url,
      suggested_filename: suggested_filename,
      page: page,
      artifact: artifact
    }
  end

  @doc """
  Creates a Download from a download event.

  ## Example

      Page.on(page, :download, fn event ->
        download = Download.from_event(event)
        Download.save_as(download, "/tmp/file.txt")
      end)
  """
  @spec from_event(Playwright.SDK.Channel.Event.t()) :: t()
  def from_event(%{target: page, params: params}) do
    new(page, params.url, params.suggestedFilename, params.artifact)
  end

  @doc "Returns the download URL."
  @spec url(t()) :: binary()
  def url(%__MODULE__{url: url}), do: url

  @doc "Returns the suggested filename for the download."
  @spec suggested_filename(t()) :: binary()
  def suggested_filename(%__MODULE__{suggested_filename: name}), do: name

  @doc "Returns the page that initiated the download."
  @spec page(t()) :: Playwright.Page.t()
  def page(%__MODULE__{page: page}), do: page

  @doc """
  Returns the path to the downloaded file after it has finished downloading.
  """
  @spec path(t()) :: binary() | {:error, term()}
  def path(%__MODULE__{artifact: artifact}) do
    Artifact.path_after_finished(artifact)
  end

  @doc """
  Saves the download to the specified path.
  """
  @spec save_as(t(), binary()) :: :ok | {:error, term()}
  def save_as(%__MODULE__{artifact: artifact}, path) do
    Artifact.save_as(artifact, path)
  end

  @doc """
  Returns the error message if download failed, nil otherwise.
  """
  @spec failure(t()) :: binary() | nil | {:error, term()}
  def failure(%__MODULE__{artifact: artifact}) do
    Artifact.failure(artifact)
  end

  @doc "Cancels the download."
  @spec cancel(t()) :: :ok | {:error, term()}
  def cancel(%__MODULE__{artifact: artifact}) do
    Artifact.cancel(artifact)
  end

  @doc "Deletes the downloaded file."
  @spec delete(t()) :: :ok | {:error, term()}
  def delete(%__MODULE__{artifact: artifact}) do
    Artifact.delete(artifact)
  end
end
