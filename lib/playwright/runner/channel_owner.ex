defmodule Playwright.Runner.ChannelOwner do
  @moduledoc false
  @base [:connection, :guid, :initializer, :parent, :type, :listeners, :waiters]

  require Logger
  alias Playwright.Runner.ChannelOwner
  alias Playwright.Runner.EventInfo

  @callback new(term(), map()) :: term()
  @callback before_event(term(), %EventInfo{}) :: {:ok, term()}

  @optional_callbacks new: 2, before_event: 2

  defmacro __using__(config \\ []) do
    extra =
      case config do
        [fields: fields] ->
          fields

        _ ->
          []
      end

    fields = extra ++ @base

    quote do
      @behaviour ChannelOwner

      @derive {Jason.Encoder, only: [:guid]}
      @derive {Inspect, only: [:guid, :initializer] ++ unquote(extra)}

      alias Playwright.Extra
      alias Playwright.Runner.Channel
      alias Playwright.Runner.Connection

      defstruct unquote(fields)

      # NOTE: need to define (on @base and :fields) the types.
      @type t() :: %__MODULE__{}

      @doc false
      def new(parent, args) do
        init(parent, args)
      end

      defoverridable(new: 2)

      @doc false
      def init(
            parent,
            %{guid: guid, initializer: initializer, type: type} = args
          ) do
        base = %__MODULE__{
          connection: parent.connection,
          guid: guid,
          initializer: initializer,
          parent: parent,
          type: type,
          listeners: %{},
          waiters: %{}
        }

        struct(
          base,
          Enum.into(unquote(extra), %{}, fn e ->
            {e, initializer[camelcase(e)]}
          end)
        )
      end

      # NOTE: probably remove this
      # !!!
      @doc false
      def patch(subject, data) do
        Task.start_link(fn ->
          Connection.patch(subject.connection, {:guid, subject.guid}, data)
        end)
      end

      @doc false
      def on_event(owner, %EventInfo{} = info) do
        {:ok, owner} = before_event(owner, info)

        event_key = Atom.to_string(info.type)
        listeners = Map.get(owner.listeners, event_key, [])
        info = %{info | target: owner}

        Enum.each(listeners, fn callback ->
          callback.(info)
        end)

        new_waiters =
          Map.get(owner.waiters, event_key, [])
          |> Enum.reduce([], fn callback, acc ->
            case callback.(info) do
              :ok -> acc
              :cont -> [callback | acc]
            end
          end)

        owner = %{owner | waiters: Map.put(owner.waiters, event_key, new_waiters)}
        {:ok, owner}
      end

      @doc false
      def before_event(owner, %EventInfo{}) do
        {:ok, owner}
      end

      defoverridable(before_event: 2)

      # private
      # ------------------------------------------------------------------------

      defp camelcase(field) when is_atom(field) do
        Extra.Atom.to_string(field)
        |> Recase.to_camel()
        |> Extra.Atom.from_string()
      end

      defp camelcase({key, value} = field) when is_tuple(field) do
        camelkey =
          Extra.Atom.to_string(key)
          |> Recase.to_camel()
          |> Extra.Atom.from_string()

        {camelkey, value}
      end
    end
  end

  @doc false
  def from(params, parent) do
    # IO.inspect(params, label: "ChannelOwner.from/2")
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
      Logger.debug(message)
      exit(message)
  end
end
