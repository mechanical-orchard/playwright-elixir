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
      alias Playwright.Channel
      alias Playwright.Channel.Event

      defstruct @properties ++ [:session, :guid, :initializer, :listeners, :parent, :type]

      @typedoc """
      %#{String.replace_prefix(inspect(__MODULE__), "Elixir.", "")}{}
      """
      @type t() :: %__MODULE__{}

      @doc false
      @spec new(struct(), map()) :: {term(), struct()}
      def new(parent, %{guid: guid, type: type, initializer: initializer} = args) do
        base = %__MODULE__{
          session: parent.session,
          guid: guid,
          initializer: initializer,
          listeners: %{},
          parent: parent,
          type: type
        }

        initializer = deep_snakecase_keys(initializer)
        init(struct(base, initializer), initializer)
      end

      @doc """
      Optional **callback** implementation for `Playwright.ChannelOwner.init/2`.

      If implemented, the callback will receive:

        1. The newly created "channel owner" struct.
        2. The `:initializer` received from the Playwright browser server.

      The implementation has the option of "patching" the struct as stored in
      the catalog, and/or binding event handlers.

      ## Example

          def init(%{session: session} = owner, _initializer) do
            Channel.bind(session, {:guid, owner.guid}, :close, fn event ->
              Logger.warning("Closing \#{inspect(event.target)}")
            end)

            {:ok, %{owner | version: "1.2.3"}}
          end

      ## Returns

        - `{:ok, struct()}`

      ## Arguments

      | key/name    | type   |            | description |
      | ------------- | ------ | ---------- | ----------- |
      | `owner`       | param  | `struct()` | The newly created channel owner (resource). |
      | `initializer` | param  | `struct()` | The initializer received from with the channel owner instance was derived. |
      """
      @spec init(struct(), map()) :: {atom(), struct()}
      def init(owner, _initializer) do
        {:ok, owner}
      end

      defoverridable(init: 2)

      require Logger

      @doc false
      @spec on_event(struct(), Event.t()) :: {term(), struct()}
      def on_event(owner, %Event{} = event) do
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

      # def find(session, {:guid, guid}) when is_binary(guid) do
      defp with_latest(%{session: session} = owner, task) do
        Channel.find(session, {:guid, owner.guid}) |> task.()
      end
    end
  end

  @doc false
  def from(params, parent) do
    module(params).new(parent, params)
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
    alias Playwright.Channel

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
          owner =
            if Map.has_key?(owner, :is_closed) && owner.is_closed do
              owner
            else
              Channel.find(owner.session, {:guid, owner.guid})
            end

          field = Map.get(owner, unquote(arg))

          if is_map(field) && Map.has_key?(field, :guid) do
            Channel.find(owner.session, {:guid, field.guid})
          else
            field
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
