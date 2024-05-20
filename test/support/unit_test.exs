defmodule Playwright.UnitTest do
  @moduledoc """
  `UnitTest` is a helper module intended for use by the tests *of* Playwright.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      defp pass(true) do
        assert true
      end

      defp pass(false) do
        assert false
      end

      defp pass(:pass) do
        assert true
      end

      defp pass(:fail) do
        assert false
      end

      defp pass({:ok, _}) do
        assert true
      end

      defp pass({:error, _}) do
        assert false
      end

      require Logger

      defp pass(other) do
        Logger.warning("pass/1 not implemented for: #{inspect(other)}")
        assert true
      end
    end
  end
end
