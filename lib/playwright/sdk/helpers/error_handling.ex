defmodule Playwright.SDK.Helpers.ErrorHandling do
  @moduledoc false
  alias Playwright.SDK.Channel.Error

  def with_timeout(options, action) when is_map(options) and is_function(action) do
    timeout = options |> Map.get(:timeout, 30_000)

    try do
      # NOTE the HACK!
      # In most cases (as of 20240802), the timeout value provided here is also
      # used as a timeout option passed to the Playwright server. As such, there
      # is/was a race condition in which the `action` provided here would often
      # time out before a response from the server indicated it's own timeout.
      action.(timeout + 5)
    catch
      :exit, {:timeout, _} = _reason ->
        {:error, Error.new(%{error: %{message: "Timeout #{inspect(timeout)}ms exceeded."}}, nil)}
    end
  end
end
