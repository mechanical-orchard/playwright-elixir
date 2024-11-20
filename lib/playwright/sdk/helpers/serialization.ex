defmodule Playwright.SDK.Helpers.Serialization do
  @moduledoc false
  require Logger
  import Playwright.SDK.Extra.Map

  def deserialize(:ok) do
    Logger.warning("Received `Playwright.SDK.Helpers.Serialization.deserialize/1` with `:ok`. It's unclear why this is happening")
    :ok
  end

  # NOTE: this is (probably) the desired API; need to work toward it.
  def deserialize({:ok, value}) do
    deserialize(value)
  end

  def deserialize(value) when is_map(value) do
    case value do
      %{a: list} ->
        Enum.map(list, fn item ->
          deserialize(item)
        end)

      %{b: boolean} ->
        boolean

      %{n: number} ->
        number

      %{o: object} ->
        Enum.map(object, fn item ->
          {item.k, deserialize(item.v)}
        end)
        |> Enum.into(%{})
        |> deep_atomize_keys()

      %{s: string} ->
        string

      %{v: "null"} ->
        nil

      %{v: "undefined"} ->
        nil
    end
  end

  def deserialize(value) when is_list(value) do
    Enum.map(value, &deserialize(&1))
  end

  def deserialize(value) when is_tuple(value) do
    case value do
      {:error, _} = error ->
        error
    end
  end

  def serialize(arg) do
    {value, handles} = serialize(arg, [], 0)
    %{value: deep_atomize_keys(value), handles: handles}
  end

  def serialize(_value, _handles, depth) when depth > 100 do
    raise ArgumentError, message: "Maximum argument depth exceeded."
  end

  # NOTE: we may want to send `undefined` instead of `null` here
  # (or, incertain cases)
  def serialize(nil, handles, _depth) do
    {%{v: "null"}, handles}
  end

  def serialize(%Playwright.ElementHandle{} = value, handles, _depth) do
    index = length(handles)
    {%{h: index}, handles ++ [%{guid: value.guid}]}
  end

  def serialize(%Playwright.JSHandle{} = value, handles, _depth) do
    index = length(handles)
    {%{h: index}, handles ++ [%{guid: value.guid}]}
  end

  require Logger

  def serialize(value, _handles, _depth) when is_float(value) do
    Logger.error("not implemented: `serialize` for float: #{inspect(value)}")
  end

  def serialize(value, handles, _depth) when is_integer(value) do
    {%{n: value}, handles}
  end

  def serialize(%DateTime{} = value, _handles, _depth) do
    Logger.error("not implemented: `serialize` for datetime: #{inspect(value)}")
  end

  def serialize(value, handles, _depth) when is_boolean(value) do
    {%{b: value}, handles}
  end

  def serialize(value, handles, _depth) when is_binary(value) do
    {%{s: value}, handles}
  end

  def serialize(value, handles, depth) when is_list(value) do
    {_, result} =
      Enum.map_reduce(value, %{handles: handles, items: []}, fn e, acc ->
        {value, handles} = serialize(e, acc.handles, depth + 1)

        {
          {value, handles},
          %{handles: handles, items: acc.items ++ [value]}
        }
      end)

    {%{a: result.items}, result.handles}
  end

  def serialize(value, handles, depth) when is_map(value) do
    {_, result} =
      Enum.map_reduce(value, %{handles: handles, objects: []}, fn {k, v}, acc ->
        {value, handles} = serialize(v, acc.handles, depth + 1)

        {
          {%{k: k, v: value}, handles},
          %{handles: handles, objects: acc.objects ++ [%{k: k, v: value}]}
        }
      end)

    {%{o: result.objects}, result.handles}
  end

  def serialize(_other, handles, _depth) do
    {%{v: "undefined"}, handles}
  end
end
