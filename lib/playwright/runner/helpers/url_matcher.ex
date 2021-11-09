defmodule Playwright.Runner.Helpers.URLMatcher do
  @moduledoc false

  defstruct([:regex])

  def new(base_url, pattern) do
    new(Enum.join([base_url, pattern], "/"))
  end

  def new(pattern) do
    %__MODULE__{
      regex: Regex.compile!(translate(pattern))
    }
  end

  # ---

  def matches(%__MODULE__{} = instance, url) do
    String.match?(url, instance.regex)
  end

  # private
  # ---------------------------------------------------------------------------

  # WARN: `translate` implementations are super naïve at the moment...
  # "**" -> ".*"
  defp translate(pattern) do
    String.replace(pattern, ~r/\*{2,}/, ".*")
  end
end
