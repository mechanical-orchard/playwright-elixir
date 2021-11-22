# A thought:
# Would it be useful to have "getter" functions that match the fields in these
# `ChannelOwner` implementations, and pull from the `Catatlog`?
defmodule Playwright.ChannelOwner do
  @moduledoc false
  @base [:connection, :guid, :listeners, :parent, :type]

  @callback init(struct(), map()) :: {atom(), struct()}
  @optional_callbacks init: 2

  defmacro __using__(options \\ []) do
    additional =
      case options do
        [fields: fields] -> fields
        _ -> []
      end

    fields = additional ++ @base

    quote do
      @behaviour Playwright.ChannelOwner

      @derive {Jason.Encoder, only: [:guid]}
      # @derive {Inspect, only: [:guid] ++ unquote(additional)}

      import Playwright.Extra.Map
      alias Playwright.Runner.{Channel, EventInfo}

      defstruct unquote(fields)
      @typedoc """
      %#{String.replace_prefix(inspect(__MODULE__), "Elixir.", "")}{}
      """
      @type t() :: %__MODULE__{}

      @doc false
      @spec new(struct(), map()) :: {term(), struct()}
      def new(parent, %{guid: guid, type: type, initializer: initializer} = args) do
        base = %__MODULE__{
          connection: parent.connection,
          guid: guid,
          listeners: %{},
          parent: parent,
          type: type
        }

        initializer = deep_snakecase_keys(initializer)
        init(struct(base, initializer), initializer)
      end

      @spec init(struct(), map()) :: {atom(), struct()}
      def init(owner, _initializer) do
        {:ok, owner}
      end

      defoverridable(init: 2)

      require Logger

      @doc false
      @spec on_event(struct(), EventInfo.t()) :: {term(), struct()}
      def on_event(owner, %EventInfo{} = event) do
        listeners = Map.get(owner.listeners, event.type, [])

        event =
          Enum.reduce(listeners, event, fn callback, acc ->
            case callback.(acc) do
              {:patch, target} ->
                Map.put(acc, :target, target)

              _ok ->
                acc
            end
          end)

        {:ok, event.target}
      end
    end
  end

  @doc false
  def from(params, parent) do
    apply(module(params), :new, [parent, params])
  end

  # private
  # ------------------------------------------------------------------------

  defp module(%{type: "Playwright"}) do
    Playwright
  end

  defp module(%{type: type}) do
    String.to_existing_atom("Elixir.Playwright.#{type}")
  rescue
    ArgumentError ->
      message = "ChannelOwner of type #{inspect(type)} is not yet defined"
      exit(message)
  end
end
