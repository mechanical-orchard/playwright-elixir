defmodule Playwright.JSHandle do
  @moduledoc """
  `Playwright.JSHandle` represents an in-page JavaScript object. `JSHandles`
  can be created with `Playwright.Page.evaluate_handle/3`.

  ## Example

      {:ok, handle} = Page.evaluate_handle(page, "() => window")

  `JSHandle` prevents the referenced JavaScript object from being garbage
  collected unless the handle is disposed with `Playwright.JSHandle.dispose/1`.
  `JSHandles` are auto-disposed when their origin frame gets navigated or the
  parent context gets destroyed.

  `JSHandle` instances can be used as arguments to:

    - `Playwright.Page.eval_on_selector/5`
    - `Playwright.Page.evaluate/3`
    - `Playwright.Page.evaluate_handle/3`
  """
  use Playwright.ChannelOwner
  alias Playwright.{ElementHandle, JSHandle}
  alias Playwright.Runner.Helpers

  @property :preview

  @doc """
  Returns either `nil` or the object handle itself, if the object handle is an instance of `Playwright.ElementHandle`.
  """
  @spec as_element(struct()) :: ElementHandle.t() | nil
  def as_element(handle)

  def as_element(%ElementHandle{} = handle) do
    handle
  end

  def as_element(%JSHandle{} = _handle) do
    nil
  end

  @doc false
  def as_element({:ok, handle}) do
    as_element(handle)
  end

  def evaluate(handle, expression, arg \\ nil) do
    params = %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    }

    Channel.post!(handle, :evaluate_expression, params)
    |> Helpers.Serialization.deserialize()
  end

  @doc """
  Returns the return value from executing `param: expression` in the browser as
  a `Playwright.JSHandle`.

  This function passes the handle as the first argument to `param: expression`.

  The only difference between `Playwright.JSHandle.evaluate/3` and
  `Playwright.JSHandle.evaluate_handle/3` is that `evaluate_handle` returns
  `Playwright.JSHandle`.

  If the expression passed to `Playwright.JSHandle.evaluate_handle/3` returns
  a `Promise`, `Playwright.JSHandle.evaluate_handle/3` waits for the promise to
  resolve and return its value.

  See `Playwright.Page.evaluate_handle/3` for more details.

  ## Returns

    - `{:ok, %Playwright.JSHandle{}}`

  ## Arguments

  | key / name    | type   |            | description |
  | ------------- | ------ | ---------- | ----------- |
  | `expression`  | param  | `binary()` | Function to be evaluated in the page context. |
  | `arg`         | param  | `any()`    | Argument to pass to `expression` `(optional)` |
  """
  @spec evaluate_handle(t() | ElementHandle.t() | {:ok, t() | ElementHandle.t()}, binary(), any()) ::
          {:ok, t() | ElementHandle.t()}
  def evaluate_handle(handle, expression, arg \\ nil)

  def evaluate_handle(%{} = handle, expression, arg) do
    params = %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    }

    Channel.post(handle, :evaluate_expression_handle, params)
  end

  def evaluate_handle({:ok, handle}, expression, arg) do
    evaluate_handle(handle, expression, arg)
  end

  def string(%{} = handle) do
    handle.preview
  end

  def string({:ok, handle}) do
    string(handle)
  end
end
