defmodule Playwright.Extra.Map do
  @moduledoc false
  alias Playwright.Extra.Atom

  def deep_atomize_keys(map) when is_map(map) do
    map
    |> Map.new(fn
      {k, v} when is_map(v) -> {Atom.from_string(k), deep_atomize_keys(v)}
      {k, list} when is_list(list) -> {Atom.from_string(k), Enum.map(list, fn v -> deep_atomize_keys(v) end)}
      {k, v} -> {Atom.from_string(k), v}
    end)
  end

  def deep_atomize_keys(not_a_map), do: not_a_map
end
