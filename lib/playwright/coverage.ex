defmodule Playwright.Coverage do
  @moduledoc """
  Coverage module for collecting JavaScript and CSS code coverage.

  This is Chromium-specific functionality.

  ## Example

      # Start JS coverage
      Coverage.start_js_coverage(page)

      # Navigate and interact
      Page.goto(page, "https://example.com")

      # Stop and get coverage data
      entries = Coverage.stop_js_coverage(page)
  """

  alias Playwright.Page
  alias Playwright.SDK.Channel

  @type js_coverage_options :: %{
          optional(:reset_on_navigation) => boolean(),
          optional(:report_anonymous_scripts) => boolean()
        }

  @type css_coverage_options :: %{
          optional(:reset_on_navigation) => boolean()
        }

  @doc """
  Starts JavaScript coverage collection.

  ## Options

  - `:reset_on_navigation` - Whether to reset coverage on every navigation (default: true)
  - `:report_anonymous_scripts` - Whether to report anonymous scripts (default: false)

  ## Returns

  - `:ok`
  """
  @spec start_js_coverage(Page.t(), js_coverage_options()) :: :ok
  def start_js_coverage(%Page{session: session, guid: guid}, options \\ %{}) do
    params = camelize_options(options)
    Channel.post(session, {:guid, guid}, "startJSCoverage", params)
    :ok
  end

  @doc """
  Stops JavaScript coverage collection and returns the coverage data.

  ## Returns

  A list of coverage entries, each containing:
  - `:url` - Script URL
  - `:scriptId` - Script ID
  - `:source` - Script source (optional)
  - `:functions` - List of function coverage data
  """
  @spec stop_js_coverage(Page.t()) :: [map()]
  def stop_js_coverage(%Page{session: session, guid: guid}) do
    Channel.post(session, {:guid, guid}, "stopJSCoverage")
  end

  @doc """
  Starts CSS coverage collection.

  ## Options

  - `:reset_on_navigation` - Whether to reset coverage on every navigation (default: true)

  ## Returns

  - `:ok`
  """
  @spec start_css_coverage(Page.t(), css_coverage_options()) :: :ok
  def start_css_coverage(%Page{session: session, guid: guid}, options \\ %{}) do
    params = camelize_options(options)
    Channel.post(session, {:guid, guid}, "startCSSCoverage", params)
    :ok
  end

  @doc """
  Stops CSS coverage collection and returns the coverage data.

  ## Returns

  A list of coverage entries, each containing:
  - `:url` - Stylesheet URL
  - `:text` - Stylesheet text (optional)
  - `:ranges` - List of used ranges
  """
  @spec stop_css_coverage(Page.t()) :: [map()]
  def stop_css_coverage(%Page{session: session, guid: guid}) do
    Channel.post(session, {:guid, guid}, "stopCSSCoverage")
  end

  defp camelize_options(options) do
    options
    |> Enum.map(fn
      {:reset_on_navigation, v} -> {:resetOnNavigation, v}
      {:report_anonymous_scripts, v} -> {:reportAnonymousScripts, v}
      other -> other
    end)
    |> Map.new()
  end
end
