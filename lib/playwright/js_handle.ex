defmodule Playwright.JSHandle do
  @moduledoc """
  `Playwright.JSHandle` represents an in-page JavaScript object. `JSHandles`
  can be created with `Playwright.Page.evaluate_handle/3`.

  ## Example

      handle = Page.evaluate_handle(page, "() => window")

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
  alias Playwright.Helpers

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

  def evaluate(%{session: session} = handle, expression, arg \\ nil) do
    params = %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    }

    Channel.post(session, {:guid, handle.guid}, :evaluate_expression, params)
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

    - `Playwright.ElementHandle.t()`

  ## Arguments

  | key/name    | type   |            | description |
  | ------------- | ------ | ---------- | ----------- |
  | `expression`  | param  | `binary()` | Function to be evaluated in the page context. |
  | `arg`         | param  | `any()`    | Argument to pass to `expression` `(optional)` |
  """
  @spec evaluate_handle(t() | ElementHandle.t(), binary(), any()) :: ElementHandle.t()
  def evaluate_handle(%{session: session} = handle, expression, arg \\ nil) do
    params = %{
      expression: expression,
      is_function: Helpers.Expression.function?(expression),
      arg: Helpers.Serialization.serialize(arg)
    }

    Channel.post(session, {:guid, handle.guid}, :evaluate_expression_handle, params)
  end

  def string(%{} = handle) do
    handle.preview
  end
end
