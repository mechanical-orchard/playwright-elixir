defmodule Playwright.APIRequest do
  @moduledoc """
  `Playwright.APIRequest` exposes an API to be used for the web API testing.

  The module is used for creating `Playwright.APIRequestContext` instances,
  which in turn may be used for sending web requests. An instance of this
  modeule may be obtained via `Playwright.request/1`.

  For more usage details, see `Playwright.APIRequestContext`.
  """

  use Playwright.SDK.Pipeline
  alias Playwright.API.Error
  alias Playwright.SDK.Channel

  @enforce_keys [:guid, :session]
  defstruct [:guid, :session]

  @typedoc """
  `#{String.replace_prefix(inspect(__MODULE__), "Elixir.", "")}`
  """
  @type t() :: %__MODULE__{
          guid: binary(),
          session: pid()
        }

  @typedoc "Options for calls to `new_context/1`"
  @type options :: map()
  # %{
  #   base_url: String.t(),
  #   extra_http_headers: map(),
  #   http_credentials: http_credentials(),
  #   ignore_https_errors: boolean(),
  #   proxy: proxy_settings(),
  #   user_agent: String.t(),
  #   timeout: float(),
  #   storage_state: storage_state() | String.t() | Path.t(),
  #   client_certificates: [client_certificate()]
  # }

  @doc """
  Returns a new `Playwright.APIRequest`.

  ## Returns

    - `Playwright.APIRequest.t()`

  ## Parameters

  - session ...
  """
  @spec new(pid()) :: t()
  def new(session) do
    %__MODULE__{
      guid: "Playwright",
      session: session
    }
  end

  @doc """
  Creates a new instance of `Playwright.APIRequestContext`.

  ## Returns

    - `Playwright.APIRequestContext.t()`
    - `{:error, Playwright.API.Error.t()}`

  ## Parameters

  - request ...
  - options

  ## Options

  | name                   | type                     |
  | ---------------------- | ------------------------ |
  | `:base_url`            | `String.t()`             |
  | `:extra_http_headers`  | `map()`                  |
  | `:http_credentials`    | `[http_credential()]`    |
  | `:ignore_https_errors` | `boolean()`              |
  | `:proxy`               | `proxy()`                |
  | `:user_agent`          | `String.t()`             |
  | `:timeout`             | `float()`                |
  | `:storage_state`       | `storage_state()`        |
  | `:client_certififates` | `[client_certificate()]` |

  ---

  ### Option: `:base_url`

  Functions such as `Playwright.APIRequestContext.get/3` take the base URL into
  consideration by using the [`URL()`](https://developer.mozilla.org/en-US/docs/Web/API/URL/URL)
  constructor for building the corresponding require URL.

  Examples:

  - With `base_url: http://localhost:3000`, sending a request to `/bar.html`
    results in `http://localhost:3000/bar.html`.
  - With `base_url: http://localhost:3000/foo/`, sending a request to `/bar.html`
    results in `http://localhost:3000/foo/bar.html`.
  - With `base_url: http://localhost:3000/foo` (without the trailing slash),
    navigating to `./bar.html` results in `http://localhost:3000/bar.html`.

  ---

  ### Option: `:extra_http_headers`

  A `map` containing additional HTTP headers to be sent with every request.

  ### Option: `:http_credentials`

  Credentials for [HTTP authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication).
  If no `:origin` is specified, the `:username` and `:password` are sent to any
  servers upon unauthorized responses.

  | name                   | type                                   |
  | ---------------------- | -------------------------------------- |
  | `:username`            | `String.t()`                           |
  | `:password`            | `String.t()`                           |
  | `:origin`              | `String.t()` (optional)                |
  | `:send`                | `"always", "unauthorized"` (optional)  |

  ---

  ### Option: `:ignore_https_errors`

  Whether to ignore HTTPS errors when sending network requests. Defaults to
  `false`.

  ---

  ### Option: `:proxy`

  Network proxy settings.

  | name        | type                    |
  | ----------- | ----------------------- |
  | `:server`   | `String.t()`            |
  | `:bypass`   | `String.t()` (optional) |
  | `:username` | `String.t()` (optional) |
  | `:password` | `String.t()` (optional) |

  ---

  ### Option: `:user_agent`

  Specific user agent to use in this context.

  ---

  ### Option: `:timeout`

  Maximum time in milliseconds to wait for the response. Defaults to `30_000`
  (30 seconds). Pass `0` to disable the timeout.

  ---

  ### Option: `:storage_state`

  Populates context with given storage state.

  This option can be used to initialize context with logged-in information
  obtained via, either, a path to the file with saved storage, or the value
  returned by one of `BrowserContext.storage_state/2` or
  `APIRequestContext.storage_state/2`.

  One of:

  - `String.t()`
  - `Path.t()`
  - Storage state

  Where storage state has the following shape:

  | name        | type      |
  | ----------- | --------- |
  | `:cookies`  | **TODO**  |
  | `:origins`  | **TODO**  |

  ---

  ### Option: `:client_certificates`

  TLS client authentication allows the server to request a client certificate
  and verify it.

  **Details**

  An array of client certificates to be used. Each certificate object must have
  both `:cert_path` and `:key_path` or a single `:pfx_path` to load the client
  certificate.

  Optionally, the `:passphrase` property should be provided if the certficiate
  is encrypted. The `:origin` property should be provided with an exact match to
  the request origin for which the certificate is valid.

  **NOTES:**

  - Using client certificates in combination with proxy servers is not supported.
  - When using WebKit on macOS, accessing `localhost` will not pick up client
    certificates. As a work-around: replace `localhost` with `local.playwright`.

  Where each client certificate has the following shape:

  | name          | type                              |
  | ------------- | --------------------------------- |
  | `:origin`     | `String.t()`                      |
  | `:cert_path`  | `Path.t(), String.t()` (optional) |
  | `:key_path`   | `Path.t(), String.t()` (optional) |
  | `:pfx_path`   | `Path.t(), String.t()` (optional) |
  | `:passphrase` | `String.t()` (optional)           |
  """
  @pipe {:new_context, [:request]}
  @pipe {:new_context, [:request, :options]}
  @spec new_context(t(), options()) :: t() | {:error, Error.t()}
  def new_context(request, options \\ %{}) do
    Channel.post({request, :new_request}, options)
  end

  # Storage State shape:
  # {
  #   cookies: [
  #     {
  #       name: str,
  #       value: str,
  #       domain: str,
  #       path: str,
  #       expires: float,
  #       httpOnly: bool,
  #       secure: bool,
  #       sameSite: Union["Lax", "None", "Strict"]
  #     }
  #   ],
  #   origins: [
  #     {
  #       origin: str,
  #       localStorage: [
  #         {
  #           name: str,
  #           value: str
  #         }
  #       ]
  #     }
  #   ]
  # }
end
