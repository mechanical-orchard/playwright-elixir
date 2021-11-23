defmodule Playwright.ChannelOwner do
  @moduledoc false
  @callback init(struct(), map()) :: {atom(), struct()}
  @optional_callbacks init: 2

  defmacro __using__(_) do
    quote do
      use Playwright.ChannelOwner.Macros
      @behaviour Playwright.ChannelOwner

      @derive {Jason.Encoder, only: [:guid]}
      @derive {Inspect, only: [:guid] ++ @properties}

      import Playwright.Extra.Map
      alias Playwright.Runner.{Channel, EventInfo}

      defstruct @properties ++ [:connection, :guid, :listeners, :parent, :type]

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

  # ChannelOwner macros
  # ---------------------------------------------------------------------------

  defmodule Macros do
    @moduledoc false

    defmacro __using__(_args) do
      Module.register_attribute(__CALLER__.module, :properties, accumulate: true)

      quote do
        import Kernel, except: [@: 1]
        import unquote(__MODULE__), only: [@: 1]
      end
    end

    def do_at(module, arg, options \\ []) do
      Module.put_attribute(module, :properties, arg)
      doc = Keyword.get(options, :doc, false)

      quote do
        @doc unquote(doc)
        @spec unquote(arg)(t()) :: term()
        def unquote(arg)(owner) do
          property = Map.get(owner, unquote(arg))

          if is_map(property) && Map.has_key?(property, :guid) do
            {:ok, result} = Playwright.Runner.Channel.find(owner, property)
            result
          else
            property
          end
        end
      end
    end

    defmacro @{:property, _meta, [arg]} do
      do_at(__CALLER__.module, arg)
    end

    defmacro @{:property, _meta, [arg, arg2]} do
      {:%{}, _, actual} = arg2
      do_at(__CALLER__.module, arg, actual)
    end

    defmacro @expr do
      quote do
        Kernel.@(unquote(expr))
      end
    end
  end
end
