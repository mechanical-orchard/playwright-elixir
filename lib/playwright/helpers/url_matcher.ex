defmodule Playwright.Helpers.URLMatcher do
  @moduledoc false

  defstruct([:match, :regex])

  def new(base_url, match) do
    new(Enum.join([base_url, match], "/"))
  end

  def new(match) do
    %__MODULE__{
      match: match,
      regex: Regex.compile!(translate(match))
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
