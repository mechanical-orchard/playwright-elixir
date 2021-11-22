defmodule Playwright.Frame do
  @moduledoc false
  use Playwright.ChannelOwner, fields: [:load_states, :url]
  alias Playwright.{ChannelOwner, ElementHandle, Frame, Page, Response}
  alias Playwright.Runner.{EventInfo, Helpers}

  @type options :: map()

  require Logger

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, _initializer) do
    Channel.bind(owner, :loadstate, fn %{params: params} = event ->
      target = event.target

      case params do
        %{add: state} ->
          {:patch, %{target | load_states: target.load_states ++ [state]}}

        %{remove: state} ->
          {:patch, %{target | load_states: target.load_states -- [state]}}
      end
    end)

    Channel.bind(owner, :navigated, fn event ->
      {:patch, %{event.target | url: event.params.url}}
    end)

    {:ok, owner}
  end

  # API
  # ---------------------------------------------------------------------------

  @spec click(struct(), binary(), map()) :: {:ok, struct()}
  def click(owner, selector, options \\ %{})

  def click(%Page{} = page, selector, options) do
    from(page) |> click(selector, options)
  end

  def click(%Frame{} = owner, selector, options) do
    params =
      Map.merge(
        %{
          selector: selector,
          timeout: 30_000,
          wait_until: "load"
        },
        options
      )

    Channel.post(owner, :click, params)
  end

  @doc false
  def click({:ok, owner}, selector, options) do
    click(owner, selector, options)
  end

  def evaluate(owner, expression, arg \\ nil)

  def evaluate(%Page{} = page, expression, arg) do
    from(page)
    |> Channel.post(:evaluate_expression, %{
      expression: expression,
      isFunction: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
    |> Helpers.Serialization.deserialize()
  end

  @doc false
  def evaluate({:ok, owner}, expression, arg) do
    evaluate(owner, expression, arg)
  end

  @spec evaluate_handle(Page.t(), binary(), term()) :: {atom(), term()}
  def evaluate_handle(page, expression, arg \\ nil)

  def evaluate_handle(%Page{} = page, expression, arg) do
    from(page)
    |> Channel.post(:evaluate_expression_handle, %{
      expression: expression,
      isFunction: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
  end

  @doc false
  def evaluate_handle({:ok, owner}, expression, arg) do
    evaluate_handle(owner, expression, arg)
  end

  @spec eval_on_selector(Frame.t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(owner, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Frame{} = owner, selector, expression, arg, _options) do
    Channel.post(owner, :eval_on_selector, %{
      selector: selector,
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    })
  end

  @spec fill(Page.t(), binary(), binary()) :: {:ok, Page.t()}
  def fill(%Page{} = owner, selector, value) do
    {:ok, _} = from(owner) |> fill(selector, value)
    {:ok, owner}
  end

  @spec fill(Frame.t(), binary(), binary()) :: {:ok, Frame.t()}
  def fill(%Frame{} = owner, selector, value) do
    {:ok, _} = Channel.post(owner, :fill, %{selector: selector, value: value})
    {:ok, owner}
  end

  @spec get_attribute(Frame.t() | Page.t(), binary(), binary(), map()) :: {:ok, binary() | nil}
  def get_attribute(owner, selector, name, options \\ %{})

  def get_attribute(%Page{} = owner, selector, name, options) do
    from(owner) |> get_attribute(selector, name, options)
  end

  def get_attribute(%Frame{} = owner, selector, name, _options) do
    owner
    |> query_selector!(selector)
    |> ElementHandle.get_attribute(name)
  end

  @spec goto(Page.t(), binary(), map()) :: {:ok, Response.t()} | {:error, term()}
  def goto(owner, url, params \\ %{})

  def goto(%Page{} = page, url, _params) do
    Channel.post(from(page), :goto, %{url: url})
  end

  @doc false
  def goto({:ok, owner}, url, params) do
    goto(owner, url, params)
  end

  def on(subject, event, handler) do
    Channel.on(subject.connection, {event, subject}, handler)
    subject
  end

  defdelegate q(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector

  @spec press(Frame.t() | Page.t(), binary(), binary(), map()) :: :ok
  def press(owner, selector, key, options \\ %{})

  def press(%Page{} = owner, selector, key, options) do
    from(owner) |> press(selector, key, options)
  end

  def press(%Frame{} = owner, selector, key, options) do
    {:ok, _} = Channel.post(owner, :press, Map.merge(%{selector: selector, key: key}, options))
    :ok
  end

  @spec query_selector(Frame.t() | Page.t(), binary(), map()) :: {:ok, ElementHandle.t() | nil}
  def query_selector(owner, selector, options \\ %{})

  def query_selector(%Page{} = page, selector, options) do
    from(page) |> query_selector(selector, options)
  end

  def query_selector(%Frame{} = owner, selector, options) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(owner, :query_selector, params)
  end

  @doc false
  def query_selector({:ok, owner}, selector, options) do
    query_selector(owner, selector, options)
  end

  defdelegate q!(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector!

  @spec query_selector!(struct(), binary(), map()) :: struct()
  def query_selector!(owner, selector, options \\ %{})

  def query_selector!(%Page{} = page, selector, options) do
    from(page) |> query_selector!(selector, options)
  end

  def query_selector!(%Frame{} = owner, selector, options) do
    case query_selector(owner, selector, options) do
      {:ok, nil} -> raise "No element found for selector: #{selector}"
      {:ok, handle} -> handle
    end
  end

  @doc false
  def query_selector!({:ok, owner}, selector, options) do
    query_selector!(owner, selector, options)
  end

  defdelegate qq(owner, selector, options \\ %{}), to: __MODULE__, as: :query_selector_all

  @spec query_selector_all(Frame.t() | Page.t(), binary(), map()) :: {atom(), [ElementHandle.t()]}
  def query_selector_all(owner, selector, options \\ %{})

  def query_selector_all(%Page{} = page, selector, options) do
    from(page) |> query_selector_all(selector, options)
  end

  def query_selector_all(%Frame{} = owner, selector, options) do
    params = Map.merge(%{selector: selector}, options)
    Channel.post(owner, :query_selector_all, params)
  end

  @doc false
  def query_selector_all({:ok, owner}, selector, options) do
    query_selector_all(owner, selector, options)
  end

  @spec set_content(struct(), binary(), map()) :: :ok
  def set_content(owner, html, options \\ %{})

  def set_content(%Page{} = page, html, options) do
    from(page) |> set_content(html, options)
  end

  def set_content(%Frame{} = owner, html, options) do
    params = Map.merge(%{html: html, timeout: 30_000, wait_until: "load"}, options)
    {:ok, _response} = Channel.post(owner, :set_content, params)
    :ok
  end

  @doc false
  def set_content({:ok, owner}, html, options) do
    set_content(owner, html, options)
  end

  @spec text_content(Frame.t() | Page.t(), binary(), map()) :: {:ok, binary() | nil}
  def text_content(owner, selector, options \\ %{})

  def text_content(%Page{} = owner, selector, options) do
    from(owner) |> text_content(selector, options)
  end

  def text_content(%Frame{} = owner, selector, options) do
    Channel.post(owner, :text_content, Map.merge(%{selector: selector}, options))
  end

  @spec title(Page.t()) :: {:ok, binary()}
  def title(%Page{} = page) do
    from(page) |> title()
  end

  @spec title(Frame.t()) :: {:ok, binary()}
  def title(%Frame{} = owner) do
    Channel.post(owner, :title)
  end

  def url(%Page{} = page) do
    from(page) |> url()
  end

  def url(%Frame{} = owner) do
    owner.url
  end

  @doc false
  def url({:ok, owner}) do
    url(owner)
  end

  @spec wait_for_selector(struct(), binary(), map()) :: {:ok, ElementHandle.t() | nil}
  def wait_for_selector(owner, selector, options \\ %{})

  def wait_for_selector(%Page{} = owner, selector, options) do
    from(owner) |> wait_for_selector(selector, options)
  end

  def wait_for_selector(%Frame{} = owner, selector, options) do
    Channel.post(owner, :wait_for_selector, Map.merge(%{selector: selector}, options))
  end

  @spec wait_for_load_state(Frame.t(), binary(), options()) :: {:ok, Frame.t()}
  def wait_for_load_state(owner, state \\ "load", options \\ %{})

  def wait_for_load_state(%Frame{} = owner, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    if Enum.member?(owner.load_states, state) do
      {:ok, owner}
    else
      {:ok, _} = Channel.wait_for(owner, :loadstate)
      {:ok, owner}
    end
  end

  def wait_for_load_state(%Frame{} = owner, state, options) when is_binary(state) do
    wait_for_load_state(owner, state, options)
  end

  def wait_for_load_state(%Frame{} = owner, options, _) when is_map(options) do
    wait_for_load_state(owner, "load", options)
  end


  # private
  # ---------------------------------------------------------------------------

  defp from(%Page{} = page) do
    {:ok, frame} = Channel.find(page, page.main_frame)
    frame
  end
end
