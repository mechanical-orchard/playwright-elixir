defmodule Playwright.Runner.ChannelOwner do
  @moduledoc false
  @base [:connection, :parent, :type, :guid, :initializer]

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
      @derive {Inspect, only: [:guid, :initializer] ++ unquote(extra)}

      alias Playwright.Extra
      alias Playwright.Runner.Channel
      alias Playwright.Runner.Connection

      defstruct unquote(fields)

      @type t() :: %__MODULE__{}

      @doc false
      def channel_owner(
            parent,
            %{guid: guid, type: type, initializer: initializer} = args
          ) do
        base = %__MODULE__{
          connection: parent.connection,
          parent: parent,
          type: type,
          guid: guid,
          initializer: initializer
        }

        struct(
          base,
          Enum.into(unquote(extra), %{}, fn e ->
            {e, initializer[camelcase(e)]}
          end)
        )
      end

      # private
      # ------------------------------------------------------------------------

      defp camelcase(atom) do
        Extra.Atom.to_string(atom)
        |> Recase.to_camel()
        |> Extra.Atom.from_string()
      end
    end
  end
end
