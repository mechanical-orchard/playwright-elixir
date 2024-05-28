defmodule Playwright.Helpers.URLMatcher do
  @moduledoc false

  defstruct([:match, :mode, :regex])

  def new(base_url, match) when is_binary(match) do
    new(Enum.join([Regex.replace(~r/\/$/, base_url, ""), match], "/"))
  end

  def new(%Regex{} = match) do
    %__MODULE__{
      match: nil,
      mode: "regex",
      regex: match
    }
  end

  def new(match) when is_binary(match) do
    %__MODULE__{
      match: match,
      mode: "glob",
      regex: Regex.compile!(glob_to_regex(match))
    }
  end

  def new(match) when is_function(match) do
    %__MODULE__{
      match: match,
      mode: "callback",
      regex: nil
    }
  end

  # ---

  def matches(%__MODULE__{mode: "callback", match: match}, url) do
    match.(url)
  end

  def matches(%__MODULE__{regex: regex}, url) do
    String.match?(url, regex)
  end

  # private
  # ---------------------------------------------------------------------------

  # WARN: `translate` implementations are super naïve at the moment...
  # "**" -> ".*"
  # TODO: replace with something like https://github.com/jonleighton/path_glob
  defp glob_to_regex(pattern) do
    String.replace(pattern, ~r/\*{2,}/, ".*")
  end
end
