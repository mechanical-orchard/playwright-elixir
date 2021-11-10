defmodule Playwright.Runner.ChannelOwner do
  @moduledoc false
  @base [:connection, :guid, :initializer, :parent, :type, :listeners]

  require Logger
  alias Playwright.Runner.Channel
  alias Playwright.Runner.ChannelOwner

  @callback before_event(term(), %Channel.Event{}) :: {:ok, term}
  @optional_callbacks before_event: 2

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
      def channel_owner(
            parent,
            %{guid: guid, initializer: initializer, type: type} = args
          ) do
        base = %__MODULE__{
          connection: parent.connection,
          guid: guid,
          initializer: initializer,
          parent: parent,
          type: type,
          listeners: %{}
        }

        struct(
          base,
          Enum.into(unquote(extra), %{}, fn e ->
            {e, initializer[camelcase(e)]}
          end)
        )
      end

      def patch(subject, data) do
        Task.start_link(fn ->
          Connection.patch(subject.connection, {:guid, subject.guid}, data)
        end)
      end

      @doc false
      def on_event(owner, %Playwright.Runner.Channel.Event{} = event) do
        {:ok, owner} = before_event(owner, event)

        handlers = (owner.listeners[Atom.to_string(event.type)] || [])
        Enum.each(handlers, fn handler ->
          handler.(owner, event)
        end)

        {:ok, owner}
      end

      @doc false
      def before_event(owner, %Playwright.Runner.Channel.Event{}) do
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
    apply(module(params), :new, [parent, params])
  end

  # private
  # ------------------------------------------------------------------------

  defp module(%{type: type}) do
    String.to_existing_atom("Elixir.Playwright.#{type}")
  rescue
    ArgumentError ->
      message = "ChannelOwner of type #{inspect(type)} is not yet defined"
      Logger.debug(message)
      exit(message)
  end
end
