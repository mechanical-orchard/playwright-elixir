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

  def deep_atomize_keys(other), do: other

  def deep_camelize_keys(list) when is_list(list) do
    Enum.into(list, %{}) |> deep_camelize_keys()
  end

  def deep_camelize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_map(v) ->
        {camelize(k), deep_camelize_keys(v)}

      {k, l} when is_list(l) ->
        {camelize(k), Enum.map(l, fn v -> deep_camelize_keys(v) end)}

      {k, v} ->
        {camelize(k), v}
    end)
  end

  def deep_camelize_keys(other), do: other

  # private
  # ----------------------------------------------------------------------------

  defp camelize(key) do
    Atom.to_string(key) |> Recase.to_camel()
  end
end
