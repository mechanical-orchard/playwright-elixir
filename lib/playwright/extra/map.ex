defmodule Playwright.Extra.Map do
  @moduledoc false
  require Logger
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
      {k, v} when is_struct(v) ->
        {camelize(k), v}

      {k, v} when is_map(v) ->
        {camelize(k), deep_camelize_keys(v)}

      {k, l} when is_list(l) ->
        {camelize(k), Enum.map(l, fn v -> deep_camelize_keys(v) end)}

      {k, v} ->
        {camelize(k), v}
    end)
  end

  def deep_camelize_keys(other), do: other

  def deep_snakecase_keys(list) when is_list(list) do
    Enum.into(list, %{}) |> deep_snakecase_keys()
  end

  def deep_snakecase_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_map(v) ->
        {snakecase(k), deep_snakecase_keys(v)}

      {k, l} when is_list(l) ->
        {snakecase(k), Enum.map(l, fn v -> deep_snakecase_keys(v) end)}

      {k, v} ->
        {snakecase(k), v}
    end)
  end

  def deep_snakecase_keys(other), do: other

  # private
  # ----------------------------------------------------------------------------

  defp camelize(key) when is_atom(key) do
    Atom.to_string(key) |> Recase.to_camel()
  end

  defp camelize(key) when is_binary(key) do
    # key

    case(String.match?(key, ~r/[A-Z]+/)) do
      true ->
        key

      false ->
        Atom.to_string(key) |> Recase.to_camel()
    end
  end

  defp snakecase(key) do
    Recase.to_snake(key) |> Atom.from_string()
  end
end
