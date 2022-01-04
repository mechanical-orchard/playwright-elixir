defmodule Playwright.Page.Accessibility do
  @moduledoc """
  `Playwright.Page.Accessibility` provides functions for inspecting Chromium's accessibility tree.

  The accessibility tree is used by assistive technology such as [screen readers][1] or [switches][2].

  Accessibility is a very platform-specific thing. On different platforms, there are different screen readers that
  might have wildly different output.

  Rendering engines of Chromium, Firefox and WebKit have a concept of "accessibility tree", which is then translated
  into different platform-specific APIs. Accessibility namespace gives access to this Accessibility Tree.

  Most of the accessibility tree gets filtered out when converting from internal browser AX Tree to Platform-specific
  AX-Tree or by assistive technologies themselves. By default, Playwright tries to approximate this filtering,
  exposing only the "interesting" nodes of the tree.

  [1]: https://en.wikipedia.org/wiki/Screen_reader
  [2]: https://en.wikipedia.org/wiki/Switch_access
  """

  alias Playwright.{Channel, ElementHandle, Extra, Page}

  @typedoc """
  Options given to `snapshot/2`

  - `:interesting_only` - Prune uninteresting nodes from the tree (default: true)
  - `:root` - The root DOM element for the snapshot (default: page)
  """
  @type options() ::
          %{}
          | %{
              interesting_only: boolean(),
              root: ElementHandle.t()
            }

  @typedoc """
  Snapshot result returned from `snapshot/2`

  - `:name` - A human readable name for the node
  - `:description` - An additional human readable description of the node, if applicable
  - `:role` - The role
  - `:value` - The current value of the node, if applicable
  - `:children` - Child nodes, if any, if applicable
  - `:autocomplete` - What kind of autocomplete is supported by a control, if applicable
  - `:checked` - Whether the checkbox is checked, or "mixed", if applicable
  - `:disabled` - Whether the node is disabled, if applicable
  - `:expanded` - Whether the node is expanded or collapsed, if applicable
  - `:focused` - Whether the node is focused, if applicable
  - `:haspopup` - What kind of popup is currently being shown for a node, if applicable
  - `:invalid` - Whether and in what way this node's value is invalid, if applicable
  - `:keyshortcuts` - Keyboard shortcuts associated with this node, if applicable
  - `:level` - The level of a heading, if applicable
  - `:modal` - Whether the node is modal, if applicable
  - `:multiline` - Whether the node text input supports multiline, if applicable
  - `:multiselectable` - Whether more than one child can be selected, if applicable
  - `:orientation` - Whether the node is oriented horizontally or vertically, if applicable
  - `:pressed` - Whether the toggle button is checked, or "mixed", if applicable
  - `:readonly` - Whether the node is read only, if applicable
  - `:required` - Whether the node is required, if applicable
  - `:roledescription` - A human readable alternative to the role, if applicable
  - `:selected` - Whether the node is selected in its parent node, if applicable
  - `:valuemax` - The maximum value in a node, if applicable
  - `:valuemin` - The minimum value in a node, if applicable
  - `:valuetext` - A description of the current value, if applicable
  """
  @type snapshot() :: %{
          name: String.t(),
          description: String.t(),
          role: String.t(),
          value: String.t() | number(),
          children: list(),
          autocomplete: String.t(),
          checked: boolean() | String.t(),
          disabled: boolean(),
          expanded: boolean(),
          focused: boolean(),
          haspopup: String.t(),
          invalid: String.t(),
          keyshortcuts: String.t(),
          level: number(),
          modal: boolean(),
          multiline: boolean(),
          multiselectable: boolean(),
          orientation: String.t(),
          pressed: boolean() | String.t(),
          readonly: boolean(),
          required: boolean(),
          roledescription: String.t(),
          selected: boolean(),
          valuemax: number(),
          valuemin: number(),
          valuetext: String.t()
        }

  @doc """
  Captures the current state of the accessibility tree.

  The result represents the root accessible node of the page.

  ## Examples

  Dumping an entire accessibility tree:

      Browser.new_page(browser)
        |> Page.set_content("<p>Hello!</p>")
        |> Page.Accessibility.snapshot()
      %{children: [%{name: "Hello!", role: "text"}], name: "", role: "WebArea"}

  Retrieving the name of a focused node:

      body = "<input placeholder='pick me' readonly /><input placeholder='not me' />"
      Browser.new_page(browser)
        |> Page.set_content(body)
        |> Page.Accessibility.snapshot()
        |> (&(Enum.find(&1.children, fn e -> e.readonly end))).()
      %{name: "pick me", readonly: true, role: "textbox"}
  """
  @spec snapshot(Page.t(), options) :: snapshot
  def snapshot(page, options \\ %{})

  def snapshot(%Page{session: session} = page, options) do
    Channel.post(session, {:guid, page.guid}, :accessibility_snapshot, prepare(options))
    |> ax_node_from_protocol()
  end

  # private
  # ---------------------------------------------------------------------------

  defp ax_node_from_protocol(nil) do
    nil
  end

  defp ax_node_from_protocol(%{role: role} = input)
       when role in ["text"] do
    ax_node_from_protocol(input, fn e -> e.role != "text" end)
  end

  defp ax_node_from_protocol(input) do
    ax_node_from_protocol(input, fn _ -> true end)
  end

  defp ax_node_from_protocol(input, filter) do
    Enum.reduce(input, %{}, fn {k, v}, acc ->
      cond do
        is_list(v) ->
          normal =
            v
            |> Enum.map(&ax_node_from_protocol/1)
            |> Enum.filter(filter)

          Map.put(acc, k, normal)

        k == :checked ->
          Map.put(acc, k, normalize_checked(v))

        k == :valueString ->
          Map.put(acc, :value, v)

        true ->
          Map.put(acc, k, v)
      end
    end)
  end

  defp normalize_checked(value) do
    case value do
      "checked" -> true
      "unchecked" -> false
      other -> other
    end
  end

  defp prepare(opts) when is_map(opts) do
    Enum.reduce(opts, %{}, fn {k, v}, acc -> Map.put(acc, prepare(k), v) end)
  end

  defp prepare(atom) when is_atom(atom) do
    Extra.Atom.to_string(atom)
    |> Recase.to_camel()
    |> Extra.Atom.from_string()
  end
end
