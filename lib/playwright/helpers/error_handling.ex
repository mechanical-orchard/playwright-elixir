defmodule Playwright.Helpers.ErrorHandling do
  @moduledoc false
  alias Playwright.Channel.Error

  def with_timeout(options, action) when is_map(options) and is_function(action) do
    timeout = options |> Map.get(:timeout, 30_000)

    try do
      action.(timeout)
    catch
      :exit, {:timeout, _} = _reason ->
        {:error, Error.new(%{error: %{message: "Timeout #{inspect(timeout)}ms exceeded."}}, nil)}
    end
  end
end
