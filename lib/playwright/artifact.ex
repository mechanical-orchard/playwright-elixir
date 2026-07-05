defmodule Playwright.Artifact do
  @moduledoc false
  use Playwright.SDK.ChannelOwner

  @doc """
  Returns the path to the downloaded file after it has finished downloading.
  """
  @spec path_after_finished(t()) :: binary() | {:error, term()}
  def path_after_finished(%__MODULE__{session: session} = artifact) do
    case Channel.post(session, {:guid, artifact.guid}, :path_after_finished) do
      %{value: path} -> path
      path when is_binary(path) -> path
      {:error, _} = error -> error
    end
  end

  @doc """
  Saves the artifact to the specified path.
  """
  @spec save_as(t(), binary()) :: :ok | {:error, term()}
  def save_as(%__MODULE__{session: session} = artifact, path) do
    case Channel.post(session, {:guid, artifact.guid}, :save_as, %{path: path}) do
      {:ok, _} -> :ok
      :ok -> :ok
      {:error, _} = error -> error
    end
  end

  @doc """
  Returns the error message if the artifact failed to download, nil otherwise.
  """
  @spec failure(t()) :: binary() | nil | {:error, term()}
  def failure(%__MODULE__{session: session} = artifact) do
    case Channel.post(session, {:guid, artifact.guid}, :failure) do
      %{error: error} -> error
      %{} -> nil
      {:error, _} = error -> error
    end
  end

  @doc """
  Cancels the download.
  """
  @spec cancel(t()) :: :ok | {:error, term()}
  def cancel(%__MODULE__{session: session} = artifact) do
    case Channel.post(session, {:guid, artifact.guid}, :cancel) do
      {:ok, _} -> :ok
      :ok -> :ok
      {:error, _} = error -> error
    end
  end

  @doc """
  Deletes the downloaded file.
  """
  @spec delete(t()) :: :ok | {:error, term()}
  def delete(%__MODULE__{session: session} = artifact) do
    case Channel.post(session, {:guid, artifact.guid}, :delete) do
      {:ok, _} -> :ok
      :ok -> :ok
      {:error, _} = error -> error
    end
  end
end
