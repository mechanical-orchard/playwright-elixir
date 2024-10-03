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
  alias Playwright.APIRequest
  alias Playwright.APIRequestContext
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
  @type options :: %{
          optional(:base_url) => String.t(),
          optional(:client_certificates) => [client_certificate()],
          optional(:extra_http_headers) => http_headers(),
          optional(:http_credentials) => http_credentials(),
          optional(:ignore_https_errors) => boolean(),
          optional(:proxy) => proxy_settings(),
          optional(:storage_state) => storage_state() | Path.t() | String.t(),
          optional(:timeout) => float(),
          optional(:user_agent) => String.t()
        }

  @typedoc """
  A client certificate to be used in requests.
  """
  @type client_certificate :: %{
          required(:origin) => String.t(),
          optional(:cert_path) => Path.t() | String.t(),
          optional(:key_path) => Path.t() | String.t(),
          optional(:pfx_path) => Path.t() | String.t(),
          optional(:passphrase) => String.t()
        }

  @typedoc """
  A `map` containing additional HTTP headers to be sent with every request.
  """
  @type http_headers :: %{required(String.t()) => String.t()}

  @typedoc "HTTP authetication credentials."
  @type http_credentials :: %{
          required(:username) => String.t(),
          required(:password) => String.t(),
          optional(:origin) => String.t(),
          optional(:send) => :always | :unauthorized
        }

  @typedoc "Network proxy settings."
  @type proxy_settings :: %{
          required(:server) => String.t(),
          optional(:bypass) => String.t(),
          optional(:username) => String.t(),
          optional(:password) => String.t()
        }

  @typedoc "Storage state settings."
  @type storage_state :: %{
          required(:cookies) => [cookie()],
          required(:origins) => [
            %{
              required(:origin) => String.t(),
              required(:local_storage) => [local_storage()]
            }
          ]
        }

  @typedoc "An HTTP cookie."
  @type cookie :: %{
          required(:name) => String.t(),
          required(:value) => String.t(),
          required(:domain) => String.t(),
          required(:path) => String.t(),
          required(:expires) => float(),
          required(:http_only) => boolean(),
          required(:secure) => boolean(),
          # same_site: "Lax" | "None" | "Strict"
          required(:same_site) => String.t()
        }

  @typedoc "Local storage settings."
  @type local_storage :: %{
          required(:name) => String.t(),
          required(:value) => String.t()
        }

  @doc """
  Returns a new `Playwright.APIRequest`.

  See also `Playwright.request/1` which is a more likely entry-point.

  ## Usage

      request = APIRequest.new(session)

  ## Arguments

  | name      | description                                  |
  | --------- | -------------------------------------------- |
  | `session` | The `pid` for the current Playwright session |

  ## Returns

    - `Playwright.APIRequest.t()`
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

  ## Usage

      request = Playwright.request(session)

      APIRequest.new_context(request)
      APIRequest.new_context(request, options)

      APIRequest.new_context!(request)
      APIRequest.new_context!(request, options)

  ## Arguments

  | name      |            | description                |
  | --------- | ---------- | -------------------------- |
  | `request` |            | The "subject" `APIRequest` |
  | `options` | (optional) | `APIRequest.options()`     |

  ## Options

  <div style="text-align: center;">⋯</div>

  ### Option: `:base_url`

  Functions such as `Playwright.APIRequestContext.get/3` take the base URL into
  consideration by using the [`URL()`](https://developer.mozilla.org/en-US/docs/Web/API/URL/URL)
  constructor for building the corresponding require URL.

  #### Examples

  - With `base_url: http://localhost:3000`, sending a request to `/bar.html`
    results in `http://localhost:3000/bar.html`.
  - With `base_url: http://localhost:3000/foo/`, sending a request to `/bar.html`
    results in `http://localhost:3000/foo/bar.html`.
  - With `base_url: http://localhost:3000/foo` (without the trailing slash),
    navigating to `./bar.html` results in `http://localhost:3000/bar.html`.

  <div style="text-align: center;">⋯</div>

  ### Option: `:client_certificates`

  A list of client certificates to be used. Each certificate instance must have
  both `:cert_path` and `:key_path` or a single `:pfx_path` to load the client
  certificate. Optionally, the `:passphrase` property should be provided if the
  certficiate is encrypted. The `:origin` property should be provided with an
  exact match to the request origin for which the certificate is valid.

  TLS client authentication allows the server to request a client certificate
  and verify it.

  > #### NOTE {: .info}
  >
  > Using client certificates in combination with proxy servers is not supported.

  > #### NOTE {: .info}
  >
  > When using WebKit on macOS, accessing `localhost` will not pick up client
  > certificates. As a work-around: replace `localhost` with `local.playwright`.

  #### Certificate details

  | name          |            | description                       |
  | ------------- | ---------- | --------------------------------- |
  | `:origin`     |            | Exact origin that the certificate is valid for. Origin includes https protocol, a hostname and optionally a port. |
  | `:cert_path`  | (optional) | Path to the file with the certificate in PEM format. |
  | `:key_path`   | (optional) | Path to the file with the private key in PEM format. |
  | `:pfx_path`   | (optional) | Path to the PFX or PKCS12 encoded private key and certificate chain. |
  | `:passphrase` | (optional) | Passphrase for the private key (PEM or PFX). |

  <div style="text-align: center;">⋯</div>

  ### Option: `:extra_http_headers`

  A `map` containing additional HTTP headers to be sent with every request.

  <div style="text-align: center;">⋯</div>

  ### Option: `:http_credentials`

  Credentials for [HTTP authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication).
  If no `:origin` is specified, the `:username` and `:password` are sent to any
  servers upon unauthorized responses.

  #### Credential details

  | name        |            | description |
  | ----------- | ---------- | ----------- |
  | `:username` |            |             |
  | `:password` |            |             |
  | `:origin`   | (optional) | Restrain sending http credentials on specific origin (`scheme://host:port`). |
  | `:send`     | (optional) | This option only applies to the requests sent from corresponding `APIRequestContext` and does not affect requests sent from the browser. `:always` - `Authorization` header with basic authentication credentials will be sent with the each API request. `:unauthorized`- the credentials are only sent when 401 (Unauthorized) response with `WWW-Authenticate` header is received. Defaults to `:unauthorized`. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:ignore_https_errors`

  Whether to ignore HTTPS errors when sending network requests. Defaults to
  `false`.

  <div style="text-align: center;">⋯</div>

  ### Option: `:proxy`

  Network proxy settings.

  | name        |            | description |
  | ----------- | ---------- | ----------- |
  | `:server`   |            | Proxy to be used for all requests. HTTP and SOCKS proxies are supported, for example `http://myproxy.com:3128` or `socks5://myproxy.com:3128`. Short form `myproxy.com:3128` is considered an HTTP proxy. |
  | `:bypass`   | (optional) | Optional comma-separated domains to bypass proxy, for example `".com, chromium.org, .domain.com"`. |
  | `:username` | (optional) | Optional username to use if HTTP proxy requires authentication. |
  | `:password` | (optional) | Optional password to use if HTTP proxy requires authentication. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:storage_state`

  Populates context with given storage state.

  This option can be used to initialize context with logged-in information
  obtained via, either, a path to the file with saved storage, or the value
  returned by one of `BrowserContext.storage_state/2` or
  `APIRequestContext.storage_state/2`.

  | name        |            | description |
  | ----------- | ---------- | ----------- |
  | `:cookies`  |            | `[APIRequest.cookie()]` |
  | `:origins`  |            | `[APIRequest.origin()]` |

  <div style="text-align: center;">⋯</div>

  ### Option: `:timeout`

  Maximum time in milliseconds to wait for the response. Defaults to `30_000`
  (30 seconds). Pass `0` to disable the timeout.

  <div style="text-align: center;">⋯</div>

  ### Option: `:user_agent`

  Specific user agent to use in this context.

  ## Returns

    - `Playwright.APIRequestContext.t()`
    - `{:error, Playwright.API.Error.t()}`
  """
  @pipe {:new_context, [:request]}
  @pipe {:new_context, [:request, :options]}
  @spec new_context(t(), options()) :: APIRequestContext.t() | {:error, Error.t()}
  def new_context(request, options \\ %{})

  def new_context(%APIRequest{} = request, %{storage_state: storage} = options) when is_binary(storage) do
    storage = Jason.decode!(File.read!(storage))
    new_context(request, Map.merge(options, %{storage_state: storage}))
  end

  def new_context(%APIRequest{} = request, options) do
    Channel.post({request, :new_request}, options)
  end
end
