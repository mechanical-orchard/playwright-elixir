defmodule Playwright.Browser do
  @moduledoc """
  A `Playwright.Browser` instance is created via:

    - `Playwright.BrowserType.launch/0`, when using the "driver" transport.
    - `Playwright.BrowserType.connect/1`, when using the "websocket" transport.

  An example of using a `Playwright.Browser` to create a `Playwright.Page`:

      alias Playwright.{Browser, Page}
      {:ok, session, browser} = Playwright.launch(:chromium)
      page = Browser.new_page(browser)

      Page.goto(page, "https://example.com")
      Browser.close(browser)

  ## Properties

    - `:name`
    - `:version`

  ## Shared options

  The follow options are applicable to both:

  `Playwright.Browser.new_context/2`
  `Playwright.Browser.new_page/2`

  | name                   | description                       |
  | ---------------------- | --------------------------------- |
  | `:accept_downloads`    | Whether to automatically download all the attachments. Defaults to `true` where all the downloads are accepted. |
  | `:base_url`            | See details below.                |
  | `:bypass_csp`          | Toggles bypassing page's Content-Security-Policy. Defaults to `false`. |
  | `:client_certificates` | See details below.                |
  | `:color_scheme`        | Emulates `"prefers-colors-scheme"` media feature, supported values are `"light"`, `"dark"`, `"no-preference"`. See `Playwright.Page.emulate_media/2` for more details. Passing `null` resets emulation to system defaults. Defaults to `"light"`. |
  | `:device_scale_factor` | Specifies a device scale factor (can be thought of as `dpr`). Defaults to `1`. Learn more about [emulating devices with device scale factor](https://playwright.dev/docs/emulation#devices). |
  | `:extra_http_headers`  | A `map` containing additional HTTP headers to be sent with every request. |
  | `:force_colors`        | Emulates `"forced-colors"` media feature, supported values are `"active"`, `"none"`. See `Playwright.Page.emulate_media/2` for more details. Passing `null` resets emulation to system defaults. Defaults to `"none"`. |
  | `:geolocation`         | See details below.                |
  | `:has_touch`           | Specifies whether the viewport supports touch events. Defaults to `false`. Learn more about [mobile emulation](https://playwright.dev/docs/emulation#devices). |
  | `:http_credentials`    | See details below.                |
  | `:ignore_https_errors` | Whether to ignore HTTPS errors when sending network requests. Defaults to `false`. |
  | `:locale`              | Specifies the user locale. For example, `en-GB`, `de-DE`, etc. Locale will affect `navigator.language` value, `Accept-Language` request header value as well as number and date formatting rules. Defaults to the system default locale. Learn more about emulation in the [emulation guide](https://playwright.dev/docs/emulation#locale--timezone). |
  | `:logger`              | Logger sink for Playwright logging. |
  | `:offline`             | Whether to emulate network being offline. Defaults to `false`. Learn more about [network emulation](https://playwright.dev/docs/emulation#offline). |
  | `:permissions`         | A list of permissions to grant to all pages in this context. See `Playwright.BrowserContext.grant_permissions/3` for more details. Defaults to `none`. |
  | `:proxy`               | See details below. |
  | `:record_har`          | See details below. |
  | `:record_video`        | See details below. |
  | `:reduced_motion`      | Emulates `"prefers-reduced-motion"` media feature, supported values are `"reduce"`, `"no-preference"`. See `Playwright.Page.emulate_media/2` for more details. Passing `null` resets emulation to system defaults. Defaults to `"no-preference"`. |
  | `:screen`              | See details below. |
  | `:service_workers`     | See details below. |
  | `:strict_selectors`    | If set to `true`, enables strict selectors mode for this context. In the strict selectors mode all operations on selectors that imply single target DOM element will throw when more than one element matches the selector. This option does not affect any `Playwright.Locator` APIs (Locators are always strict). Defaults to `false`. See `Playwright.Locator` to learn more about the strict mode. |
  | `:timezone_id`         | Changes the timezone of the context. See [ICU's metaZones.txt](ICU's metaZones.txt) for a list of supported timezone IDs. Defaults to the system timezone. |
  | `:user_agent`          | Specific user agent to use in this context. |
  | `:video_size`          | See details below. |
  | `:videos_path`         | See details below. |
  | `:viewport`            | See details below. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:base_url`

  When using `Page.goto/3`, `Page.route/4`, `Page.wait_for_url/3`,
  `Page.wait_for_request/3`, or `Page.wait_for_response/3`, the base URL is
  taken into consideration using the [`URL()`](https://developer.mozilla.org/en-US/docs/Web/API/URL/URL)
  constructor for building the corresponding URL. Unset by default.

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

  #### Details

  | name          |            | description                       |
  | ------------- | ---------- | --------------------------------- |
  | `:origin`     |            | Exact origin that the certificate is valid for. Origin includes https protocol, a hostname and optionally a port. |
  | `:cert_path`  | (optional) | Path to the file with the certificate in PEM format. |
  | `:key_path`   | (optional) | Path to the file with the private key in PEM format. |
  | `:pfx_path`   | (optional) | Path to the PFX or PKCS12 encoded private key and certificate chain. |
  | `:passphrase` | (optional) | Passphrase for the private key (PEM or PFX). |

  ### Option: `:geolocation`

  Browser geolocation settings.

  #### Details

  | name          |            | description                       |
  | ------------- | ---------- | --------------------------------- |
  | `:latitude`   |            | Latitude between `-90` and `90`.  |
  | `:longitude`  |            | Longitude between `-180` and `180`. |
  | `:accuracy`   | (optional) | Non-negative accuracy value. Defaults to `0`. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:http_credentials`

  Credentials for [HTTP authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication).

  This option only applies to the requests sent from corresponding a
  `Playwright.APIRequestContext` and does not affect requests sent from the
  `Browser`.

  #### Details

  | name        |            | description |
  | ----------- | ---------- | ----------- |
  | `:username` |            |             |
  | `:password` |            |             |
  | `:origin`   | (optional) | Restrain sending http credentials on specific origin (`scheme://host:port`). |
  | `:send`     | (optional) | This option only applies to the requests sent from corresponding `APIRequestContext` and does not affect requests sent from the browser. `:always` - `Authorization` header with basic authentication credentials will be sent with the each API request. `:unauthorized`- the credentials are only sent when 401 (Unauthorized) response with `WWW-Authenticate` header is received. Defaults to `:unauthorized`. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:proxy`

  Network proxy settings.

  #### Details

  | name        |            | description |
  | ----------- | ---------- | ----------- |
  | `:server`   |            | Proxy to be used for all requests. HTTP and SOCKS proxies are supported, for example `http://myproxy.com:3128` or `socks5://myproxy.com:3128`. Short form `myproxy.com:3128` is considered an HTTP proxy. |
  | `:bypass`   | (optional) | Optional comma-separated domains to bypass proxy, for example `".com, chromium.org, .domain.com"`. |
  | `:username` | (optional) | Optional username to use if HTTP proxy requires authentication. |
  | `:password` | (optional) | Optional password to use if HTTP proxy requires authentication. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:record_har`

  Enables HAR recording for all pages into `:record_har.path` file. If not
  specified, the HAR is not recorded. Be sure to await
  `Playwright.BrowserContext.close/1` for the HAR to be saved.

  #### Details

  | name            |            | description |
  | --------------- | ---------- | ----------- |
  | `:omit_content` | (optional) | Optional setting to control whether to omit request content from the HAR. Defaults to `false`. **Deprecated**; use content policy instead. |
  | `:content`      | (optional) | Optional setting to control resource content management. If `omit` is specified, content is not persisted. If `attach` is specified, resources are persisted as separate files or entries in the ZIP archive. If `embed` is specified, content is stored inline the HAR file as per HAR specification. Defaults to `attach` for `.zip` output files and to `embed` for all other file extensions. |
  | `:path`         |            | Path on the filesystem to write the HAR file. If the file name ends with `.zip`, `content: 'attach'` is used by default. |
  | `:mode`         | (optional) | When set to `minimal`, only record information necessary for routing from HAR. This omits sizes, timing, page, cookies, security and other types of HAR information that are not used when replaying from HAR. Defaults to `full`. |
  | `:url_filter`   | (optional) | A glob or regex pattern to filter requests that are stored in the HAR. When a `:base_url` via the context options was provided and the passed URL is a path, it gets merged via the `new URL()` constructor. Defaults to `none`. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:record_video`

  Enables video recording for all pages into `:record_video.dir` directory. If
  not specified videos are not recorded. Be sure to await
  `Playwright.BrowserContext.close/1` for videos to be saved.

  #### Details

  | name            |            | description |
  | --------------- | ---------- | ----------- |
  | `:dir`          |            | Path to the directory for saving videos. |
  | `:size`         | (optional) | Video frame with and height: `%{width: number(), height: number()}`. |
  | `:path`         |            | Path on the filesystem to write the HAR file. If the file name ends with `.zip`, `content: 'attach'` is used by default. |
  | `:mode`         | (optional) | When set to `minimal`, only record information necessary for routing from HAR. This omits sizes, timing, page, cookies, security and other types of HAR information that are not used when replaying from HAR. Defaults to `full`. |
  | `:url_filter`   | (optional) | Optional dimensions of the recorded videos. If not specified the size will be equal to `viewport` scaled down to fit into 800x800. If `viewport` is not configured explicitly the video size defaults to 800x450. Actual picture of each page will be scaled down if necessary to fit the specified size. |

  - `:size`:
    - `:width` - `number()`: Video frame width.
    - `:height` - `number()`: Video frame height.

  <div style="text-align: center;">⋯</div>

  ### Option: `:screen`

  Emulates consistent window screen size available inside web page via
  `window.screen`. Is only used when the `viewport` is set.

  #### Details

  | name            |            | description |
  | --------------- | ---------- | ----------- |
  | `:width`        |            | Page width in pixels. |
  | `:height`       |            | Page height in pixels. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:service_workers`

  Whether to allow sites to register Service workers. Defaults to `"allow"`.

  #### Details

  - `"allow"`: [Service Workers](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API) can be registered.
  - `"block"`: Playwright will block all registration of Service Workers.

  <div style="text-align: center;">⋯</div>

  ### Option: `:storage_state`

  Populates context with given storage state.

  This option can be used to initialize context with logged-in information
  obtained via, either, a path to the file with saved storage, or the value
  returned by `BrowserContext.storage_state/2`.

  Learn more about [storage state and auth](https://playwright.dev/docs/auth).

  | name        |            | description |
  | ----------- | ---------- | ----------- |
  | `:cookies`  |            | `[Browser.cookie()]` |
  | `:origins`  |            | `[Browser.origin()]` |

  <div style="text-align: center;">⋯</div>

  ### Option: `:video_size`

  > #### DEPRECATED {: .warn}
  >
  > Use `:record_video` instead.

  #### Details

  | name      |            | description |
  | --------- | ---------- | ----------- |
  | `:width`  |            | Video frame width. |
  | `:height` |            | Video frame height. |

  <div style="text-align: center;">⋯</div>

  ### Option: `:videos_path`

  > #### DEPRECATED {: .warn}
  >
  > Use `:record_video` instead.

  <div style="text-align: center;">⋯</div>

  ### Option: `:viewport`

  Emulates consistent viewport for each page. Defaults to an 1280x720 viewport.
  Use `null` to disable the consistent viewport emulation. Learn more about
  [viewport emulation](https://playwright.dev/docs/emulation#viewport).

  > #### INFO {: .info}
  >
  > The `null` value opts out from the default presets, makes viewport depend on
  > the host window size defined by the operating system. It makes the execution
  > of the tests non-deterministic.

  #### Details

  | name      |            | description |
  | --------- | ---------- | ----------- |
  | `:width`  |            | Page width in pixels. |
  | `:height` |            | Page height in pixels. |
  """
  use Playwright.SDK.ChannelOwner
  alias ExUnit.DocTest.Error
  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.BrowserType
  alias Playwright.CDPSession
  alias Playwright.Page
  alias Playwright.SDK.Channel
  alias Playwright.SDK.ChannelOwner
  alias Playwright.SDK.Extra

  @property :name
  @property(:version, %{doc: "Returns the browser version"})

  @typedoc "Supported events"
  @type event :: :disconnected

  @typedoc "Options for `close/2`."
  @type opts_close :: %{
          optional(:reason) => String.t()
        }

  @typedoc "Options for `new_context/2` and `new_page/2`."
  @type opts_new :: %{
          optional(:accept_downloads) => boolean(),
          optional(:base_url) => String.t(),
          optional(:bypass_csp) => boolean(),
          optional(:client_certificates) => [client_certificate()],
          optional(:color_scheme) => color_scheme(),
          optional(:device_scale_factor) => number(),
          optional(:extra_http_headers) => http_headers(),
          optional(:forced_colors) => forced_colors(),
          optional(:geolocation) => geolocation(),
          optional(:has_touch) => boolean(),
          optional(:http_credentials) => http_credentials(),
          optional(:ignore_https_errors) => boolean(),
          optional(:is_mobile) => boolean(),
          optional(:javascript_enabled) => boolean(),
          optional(:locale) => String.t(),
          optional(:logger) => Playwright.Logger.t(),
          optional(:offline) => boolean(),
          optional(:permissions) => [String.t()],
          optional(:proxy) => proxy_settings(),
          optional(:record_har) => har_settings(),
          optional(:record_video) => video_settings(),
          optional(:reduced_motion) => motion_settings(),
          optional(:screen) => screen_settings(),
          optional(:service_workers) => worker_settings(),
          optional(:storage_state) => storage_state(),
          optional(:strict_selectors) => boolean(),
          optional(:timezone_id) => String.t(),
          optional(:user_agent) => String.t(),
          optional(:video_size) => map(),
          optional(:videos_path) => String.t(),
          optional(:viewport) => viewport_settings()
        }

  @typedoc "A client TLS certificate to be used in requests."
  @type client_certificate :: %{
          required(:origin) => String.t(),
          optional(:cert_path) => Path.t() | String.t(),
          optional(:key_path) => Path.t() | String.t(),
          optional(:pfx_path) => Path.t() | String.t(),
          optional(:passphrase) => String.t()
        }

  @typedoc """
  A value used to emulate "prefers-color-scheme" media feature.

  - `"light"`
  - `"dark"`
  - `"no-preference"`
  - `nil`
  """
  @type color_scheme :: String.t() | nil

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

  @typedoc """
  A value used to emulate "forced-colors" media feature.

  - `"active"`
  - `"none"`
  - `nil`
  """
  @type forced_colors :: String.t() | nil

  @typedoc "Geolocation emulation settings."
  @type geolocation :: %{
          required(:latitude) => number(),
          required(:longitude) => number(),
          optional(:accuracy) => number()
        }

  @typedoc """
  HAR recording settings.

  - `:content`:
    - `"omit"`
    - `"embed"`
    - `"attach"`
  - `:mode`:
    - `"full"`
    - `"minimal"`
  """
  @type har_settings :: %{
          optional(:omit_content) => boolean(),
          optional(:content) => String.t(),
          required(:path) => String.t(),
          optional(:mode) => String.t(),
          optional(:url_filter) => String.t() | Regex.t()
        }

  @typedoc "HTTP authetication credentials."
  @type http_credentials :: %{
          required(:username) => String.t(),
          required(:password) => String.t(),
          optional(:origin) => String.t(),
          optional(:send) => :always | :unauthorized
        }

  @typedoc "A `map` containing additional HTTP headers to be sent with every request."
  @type http_headers :: %{required(String.t()) => String.t()}

  @typedoc "Local storage settings."
  @type local_storage :: %{
          required(:name) => String.t(),
          required(:value) => String.t()
        }

  @typedoc "Network proxy settings."
  @type proxy_settings :: %{
          required(:server) => String.t(),
          optional(:bypass) => String.t(),
          optional(:username) => String.t(),
          optional(:password) => String.t()
        }

  @typedoc """
  Settings for emulating "prefers-reduced-motion" media feature

  - `"reduce"`
  - `"no-preference"`
  - `nil`
  """
  @type motion_settings :: %{
          required(:server) => String.t(),
          optional(:bypass) => String.t(),
          optional(:username) => String.t(),
          optional(:password) => String.t()
        }

  @typedoc "Window screen size settings."
  @type screen_settings :: %{
          required(:width) => number(),
          required(:height) => number()
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

  @typedoc "Video recording settings."
  @type video_settings :: %{
          required(:dir) => String.t(),
          optional(:size) => %{
            width: number(),
            height: number()
          }
        }

  @typedoc "Viewport settings."
  @type viewport_settings :: %{
          required(:width) => number(),
          required(:height) => number()
        }

  @typedoc """
  Window screen size settings.

  - `"allow"`
  - `"block"`
  """
  @type worker_settings :: String.t()

  @typedoc "Options for tracing API."
  @type opts_tracing :: map()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(browser, _initializer) do
    {:ok, %{browser | version: cut_version(browser.version)}}
  end

  # API
  # ---------------------------------------------------------------------------

  @doc """
  Get the `Playwright.BrowserType` (as, `:chromium`, `:firefox` or `:webkit`)
  to which this `Playwright.Browser` belongs.

  Usage

      Browser.browser_type(browser);

  Returns

    - `Playwright.BrowserType.t()`
  """
  @spec browser_type(t()) :: BrowserType.t()
  def browser_type(%Browser{} = browser) do
    browser.parent
  end

  @doc """
  Closes the browser.

  Given a `Playwright.Browser` obtained from `Playwright.BrowserType.launch/2`,
  closes the `Browser` and all of its `Pages` (if any were opened).

  Given a `Playwright.Browser` obtained via `Playwright.BrowserType.connect/2`,
  clears all created `Contexts` belonging to this `Browser` and disconnects
  from the browser server.

  > #### NOTE {: .info}
  >
  > This is similar to force-quitting the browser. Therefore, be sure to call
  > `Playwright.BrowserContext.close/1` on any `BrowserContext` instances
  > explicitly created earlier by calling `Browser.new_context/1` before calling
  > `Browser.close/2`.

  The `Browser` instance itself is considered to be disposed and cannot be
  used any longer.

  ## Usage

      Browser.close(browser)
      Browser.close(browser, %{reason: "All done."})

  ## Arguments

  | name      |            | description             |
  | --------- | ---------- | ----------------------- |
  | `browser` |            | The "subject" `Browser` |
  | `options` | (optional) | `Browser.opts_close()`  |

  ## Options

  | name      |            | description                       |
  | --------- | ---------- | --------------------------------- |
  | `:reason` | (optional) | The reason to be reported to any operations interrupted by the browser closure. |

  ## Returns

    - `:ok`

  """
  @spec close(t(), opts_close()) :: :ok
  def close(%Browser{session: session} = browser, options \\ %{}) do
    case Channel.find(session, {:guid, browser.guid}, %{timeout: 10}) do
      %Browser{} ->
        Channel.close(browser, options)

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Returns a list of all open browser contexts.

  For a newly created `Playwright.Browser`, this will return zero contexts.

  ## Usage

      contexts = Browser.contexts(browser)
      assert Enum.empty?(contexts)

      Browser.new_context(browser)

      contexts = Browser.contexts(browser)
      assert length(contexts) == 1

  ## Arguments

  | name      |            | description             |
  | --------- | ---------- | ----------------------- |
  | `browser` |            | The "subject" `Browser` |


  ## Returns

  - `[Playwright.BrowserContext.t()]`

  """
  @spec contexts(t()) :: [BrowserContext.t()]
  def contexts(%Browser{} = browser) do
    Channel.list(browser.session, {:guid, browser.guid}, "BrowserContext")
  end

  @doc """
  Returns a new `Playwright.CDPSession` instance.

  > #### NOTE {: .info}
  >
  > CDP Sessions are only supported on Chromium-based browsers.

  ## Usage

      sesssion = Browser.new_browser_cdp_session(browser)

  ## Arguments

  | name      |            | description             |
  | --------- | ---------- | ----------------------- |
  | `browser` |            | The "subject" `Browser` |

  ## Returns

  - `[Playwright.CDPSession.t()]`
  - `{:error, %Error{}}`
  """
  @spec new_browser_cdp_session(t()) :: CDPSession.t() | {:error, Error.t()}
  def new_browser_cdp_session(browser) do
    Channel.post({browser, "newBrowserCDPSession"})
  end

  @doc """
  Creates a new `Playwright.BrowserContext` for this `Playwright.Browser`.

  A `BrowserContext` does not share cookies/cache with other `BrowserContexts`
  and is somewhat equivalent to an "incognito" browser "window".

  > #### NOTE {: .info}
  >
  > If directly using this method to create `BrowserContext` instances, it is a
  > best practice to explicitly close the returned context via
  > `Playwright.BrowserContext.close/1` when your code is finished with the
  > `BrowserContext` and before calling `Playwright.Browser.close/2`.
  > This approach will ensure the context is closed gracefully and any artifacts
  > (e.g., HARs and videos) are fully flushed and saved.

  ## Usage

      # create a new "incognito" browser context.
      context = Browser.new_context(browser)

      # create a new page in a pristine context.
      page = BrowserContext.new_page(context)

      Page.goto(page, "https://example.com")

  ## Arguments

  | name      |            | description              |
  | --------- | ---------- | ------------------------ |
  | `browser` |            | The "subject" `Browser`  |
  | `options` | (optional) | `Browser.opts_new()`     |

  ## Options

  See "Shared options" above.

  ## Returns

    - `Playwright.BrowserContext.t()`
    - `{:error, Error.t()}`
  """
  @spec new_context(t(), opts_new()) :: BrowserContext.t() | {:error, Error.t()}
  def new_context(%Browser{} = browser, options \\ %{}) do
    Channel.post({browser, :new_context}, prepare(options))
  end

  @doc """
  Create a new `Playwright.Page` for this Browser, within a new "owned"
  `Playwright.BrowserContext`.

  That is, `Playwright.Browser.new_page/2` will also create a new
  `Playwright.BrowserContext`. That `BrowserContext` becomes, both, the
  *parent* of the `Page`, and *owned by* the `Page`. When the `Page` closes,
  the context goes with it.

  This is a convenience API function that should only be used for single-page
  scenarios and short snippets. Production code and testing frameworks should
  explicitly create via `Playwright.Browser.new_context/2` followed by
  `Playwright.BrowserContext.new_page/2`, given the new context, to manage
  resource lifecycles.

  ## Usage

      Browser.new_page(browser)
      Browser.new_page(browser, options)

  ## Arguments

  | name      |            | description              |
  | --------- | ---------- | ------------------------ |
  | `browser` |            | The "subject" `Browser`  |
  | `options` | (optional) | `Browser.opts_new()`     |

  ## Options

  See "Shared options" above.

  ## Returns

    - `Playwright.Page.t()`
    - `{:error, Error.t()}`
  """
  @spec new_page(t(), opts_new()) :: {Page.t() | {:error, Error.t()}}
  def new_page(browser, options \\ %{})

  def new_page(%Browser{session: session} = browser, options) do
    context = new_context(browser, options)

    case BrowserContext.new_page(context) do
      {:error, _} = error ->
        error

      page ->
        # establish co-dependency
        Channel.patch(session, {:guid, context.guid}, %{owner_page: page})
        Channel.patch(session, {:guid, page.guid}, %{owned_context: context})
        page
    end
  end

  # ---

  @spec start_tracing(t(), Page.t(), opts_tracing()) :: t() | {:error, Error.t()}
  def start_tracing(browser, page \\ nil, options \\ %{})

  def start_tracing(%Browser{} = browser, _page, _options) do
    Channel.post({browser, :start_tracing})
  end

  @spec stop_tracing(t()) :: binary()
  def stop_tracing(%Browser{} = browser) do
    Channel.post({browser, :stop_tracing})
  end

  # events
  # ----------------------------------------------------------------------------

  # test_browsertype_connect.py
  # @spec on(t(), event(), function()) :: Browser.t()
  # def on(browser, event, callback)

  # private
  # ----------------------------------------------------------------------------

  # Chromium version is \d+.\d+.\d+.\d+, but that doesn't parse well with
  # `Version`. So, until it causes issue we're cutting it down to
  # <major.minor.patch>.
  defp cut_version(version) do
    version |> String.split(".") |> Enum.take(3) |> Enum.join(".")
  end

  defp prepare(%{extra_http_headers: headers}) do
    %{
      extraHTTPHeaders:
        Enum.reduce(headers, [], fn {k, v}, acc ->
          [%{name: k, value: v} | acc]
        end)
    }
  end

  defp prepare(opts) when is_map(opts) do
    Enum.reduce(opts, %{}, fn {k, v}, acc -> Map.put(acc, prepare(k), v) end)
  end

  defp prepare(string) when is_binary(string) do
    string
  end

  defp prepare(atom) when is_atom(atom) do
    Extra.Atom.to_string(atom)
    |> Recase.to_camel()
    |> Extra.Atom.from_string()
  end
end
