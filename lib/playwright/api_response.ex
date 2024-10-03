defmodule Playwright.APIResponse do
  @moduledoc """
  `Playwright.APIResponse` represents responses returned by
  `Playwrigh.APIRequestContext.fetch/3` and similar.

  ## Usage

      request = Playwright.request(session)
      context = APIRequest.new_context(request)

      response = APIRequest.get(context, "https://example.com")
      json = APIResponse.json(response)
  """

  use Playwright.SDK.Pipeline
  alias Playwright.APIRequestContext
  alias Playwright.APIResponse
  alias Playwright.API.Error
  alias Playwright.SDK.Channel

  defstruct [:context, :fetchUid, :headers, :status, :statusText, :url]

  @typedoc """
  `#{String.replace_prefix(inspect(__MODULE__), "Elixir.", "")}`
  """
  @type t() :: %__MODULE__{
          context: APIRequestContext,
          fetchUid: String.t(),
          headers: list(%{name: String.t(), value: String.t()}),
          status: integer(),
          statusText: String.t(),
          url: String.t()
        }

  @typedoc "Data serializable as JSON."
  @type serializable() :: list() | map()

  @doc """
  Returns a `Playwright.APIResponse` hydrated from the provided `properties`.

  ## Returns

  - `Playwright.APIResponse`
  """
  @spec new(map()) :: t()
  def new(properties) do
    struct(__MODULE__, properties)
  end

  @doc """
  Returns a buffer with the response body.

  ## Returns

  - `binary()`
  - `{:error, %Error{type: "ResponseError"}}`
  """
  @pipe {:body, [:response]}
  @spec body(t()) :: binary() | {:error, Error.t()}
  def body(%APIResponse{} = response) do
    case Channel.post({response.context, :fetch_response_body}, %{fetch_uid: response.fetchUid}) do
      {:error, %Error{}} = error ->
        error

      nil ->
        {:error, Error.new(%{error: %{name: "ResponseError", message: "Response has been disposed"}}, nil)}

      result ->
        Base.decode64!(result)
    end
  end

  @doc """
  Disposes the body of the response. If not called, the body will stay in memory
  until the context closes.

  ## Returns

  - `:ok`
  - `{:error, %Error{}}`
  """
  @pipe {:dispose, [:response]}
  @spec dispose(t()) :: :ok | {:error, Error.t()}
  def dispose(%APIResponse{} = response) do
    case Channel.post({response.context, "disposeAPIResponse"}, %{fetch_uid: response.fetchUid}) do
      {:error, %Playwright.API.Error{} = error} ->
        {:error, error}

      _ ->
        :ok
    end
  end

  # ---

  # @spec headers(t()) :: map()
  # def headers(response)

  # ---

  @doc """
  Returns the value of a header.

  ## Arguments

  | name       |            | description                   |
  | ---------- | ---------- | ----------------------------- |
  | `response` |            | The "subject" `APIResponse`   |
  | `name`     |            | The name of the HTTP header   |

  ## Returns

  - `binary()`
  - `nil`
  """
  @pipe {:header, [:response, :name]}
  @spec header(t(), atom() | String.t()) :: binary() | nil
  def header(response, name)

  def header(%APIResponse{} = response, name) when is_atom(name) do
    header(response, Atom.to_string(name))
  end

  def header(%APIResponse{} = response, name) when is_binary(name) do
    case Enum.find(response.headers, fn header -> header.name == name end) do
      nil ->
        nil

      %{value: value} ->
        value
    end
  end

  # ---

  # @spec headers(t()) :: map()
  # def headers(response)

  # @spec headers_list(APIResponse.t()) :: [map()]
  # def headers_list(response)

  # ---

  @doc """
  Returns a deserialized version of the JSON representation of response body.

  ## Returns

  - `serializable()`
  - `{:error, %Error{name: "ResponseError"}}`
  """
  @pipe {:json, [:response]}
  @spec json(t()) :: serializable() | {:error, Error.t()}
  def json(%APIResponse{} = response) do
    case body(response) do
      {:error, %Error{}} = error ->
        error

      result ->
        case Jason.decode(result) do
          {:ok, decoded} ->
            decoded

          {:error, original} ->
            Error.new(%{error: %{name: "ResponseError", message: "Failed to decode response into JSON", original: original}}, nil)
        end
    end
  end

  @doc """
  Returns a boolean indicating whether the response was successful.

  Success means the response status code is within the range of `200-299`.
  """
  @pipe {:ok, [:response]}
  @spec ok(t()) :: boolean()
  def ok(%APIResponse{} = response) do
    response.status === 0 || (response.status >= 200 && response.status <= 299)
  end

  @doc """
  Returns a text representation of response body.

  ## Returns

  - `binary()`
  - `{:error, %Error{name: "ResponseError"}}`
  """
  @pipe {:text, [:response]}
  @spec text(t()) :: binary() | {:error, Error.t()}
  def text(%APIResponse{} = response) do
    body(response)
  end
end
