defmodule Playwright.Clock do
  @moduledoc """
  Clock provides methods for controlling time in tests.

  Accessed via BrowserContext. Call `Clock.install/2` before using other methods.

  ## Example

      context = Browser.new_context(browser)
      Clock.install(context, %{time: "2024-01-01T00:00:00Z"})
      Clock.fast_forward(context, "01:00:00")  # 1 hour

  ## Time Formats

  Time can be specified as:
  - Number: milliseconds since epoch (e.g., `1704067200000`)
  - String: ISO 8601 format (e.g., `"2024-01-01T00:00:00Z"`)
  - DateTime: Elixir DateTime struct

  ## Ticks Formats

  Ticks (duration) can be specified as:
  - Number: milliseconds (e.g., `1000` = 1 second)
  - String: `"mm:ss"` or `"hh:mm:ss"` format (e.g., `"01:30"` = 90 seconds)
  """

  alias Playwright.BrowserContext
  alias Playwright.SDK.Channel

  @doc """
  Install fake timers. Must be called before using other clock methods.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `context` | `BrowserContext.t()` | The browser context |
  | `options` | `map()` | Optional settings |

  ## Options

  - `:time` - Initial time (number ms, ISO string, or DateTime)

  ## Returns

  - `:ok`
  """
  @spec install(BrowserContext.t(), map()) :: :ok
  def install(%BrowserContext{session: session, guid: guid}, options \\ %{}) do
    params = parse_time_param(options[:time])
    Channel.post(session, {:guid, guid}, :clock_install, params)
    :ok
  end

  @doc """
  Advance time by jumping forward, firing due timers along the way.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `context` | `BrowserContext.t()` | The browser context |
  | `ticks` | `number() \\| String.t()` | Duration to advance (ms or "hh:mm:ss") |

  ## Returns

  - `:ok`
  """
  @spec fast_forward(BrowserContext.t(), number() | String.t()) :: :ok
  def fast_forward(%BrowserContext{session: session, guid: guid}, ticks) do
    params = parse_ticks_param(ticks)
    Channel.post(session, {:guid, guid}, :clock_fast_forward, params)
    :ok
  end

  @doc """
  Pause the clock at the specified time.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `context` | `BrowserContext.t()` | The browser context |
  | `time` | `number() \\| String.t() \\| DateTime.t()` | Time to pause at |

  ## Returns

  - `:ok`
  """
  @spec pause_at(BrowserContext.t(), number() | String.t() | DateTime.t()) :: :ok
  def pause_at(%BrowserContext{session: session, guid: guid}, time) do
    params = parse_time_param(time)
    Channel.post(session, {:guid, guid}, :clock_pause_at, params)
    :ok
  end

  @doc """
  Resume the clock after it was paused.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `context` | `BrowserContext.t()` | The browser context |

  ## Returns

  - `:ok`
  """
  @spec resume(BrowserContext.t()) :: :ok
  def resume(%BrowserContext{session: session, guid: guid}) do
    Channel.post(session, {:guid, guid}, :clock_resume, %{})
    :ok
  end

  @doc """
  Run the clock for the specified time, firing all due timers.

  Unlike `fast_forward/2`, this executes timers synchronously.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `context` | `BrowserContext.t()` | The browser context |
  | `ticks` | `number() \\| String.t()` | Duration to run (ms or "hh:mm:ss") |

  ## Returns

  - `:ok`
  """
  @spec run_for(BrowserContext.t(), number() | String.t()) :: :ok
  def run_for(%BrowserContext{session: session, guid: guid}, ticks) do
    params = parse_ticks_param(ticks)
    Channel.post(session, {:guid, guid}, :clock_run_for, params)
    :ok
  end

  @doc """
  Set the clock to a fixed time. Time will not advance automatically.

  Useful for testing time-dependent behavior at a specific moment.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `context` | `BrowserContext.t()` | The browser context |
  | `time` | `number() \\| String.t() \\| DateTime.t()` | Time to fix at |

  ## Returns

  - `:ok`
  """
  @spec set_fixed_time(BrowserContext.t(), number() | String.t() | DateTime.t()) :: :ok
  def set_fixed_time(%BrowserContext{session: session, guid: guid}, time) do
    params = parse_time_param(time)
    Channel.post(session, {:guid, guid}, :clock_set_fixed_time, params)
    :ok
  end

  @doc """
  Set the system time but allow it to advance naturally.

  Unlike `set_fixed_time/2`, time will continue to flow after being set.

  ## Arguments

  | key/name | type | description |
  | -------- | ---- | ----------- |
  | `context` | `BrowserContext.t()` | The browser context |
  | `time` | `number() \\| String.t() \\| DateTime.t()` | Time to set |

  ## Returns

  - `:ok`
  """
  @spec set_system_time(BrowserContext.t(), number() | String.t() | DateTime.t()) :: :ok
  def set_system_time(%BrowserContext{session: session, guid: guid}, time) do
    params = parse_time_param(time)
    Channel.post(session, {:guid, guid}, :clock_set_system_time, params)
    :ok
  end

  # Private helpers

  defp parse_time_param(nil), do: %{}
  defp parse_time_param(time) when is_number(time), do: %{timeNumber: time}
  defp parse_time_param(time) when is_binary(time), do: %{timeString: time}
  defp parse_time_param(%DateTime{} = dt), do: %{timeNumber: DateTime.to_unix(dt, :millisecond)}

  defp parse_ticks_param(ticks) when is_number(ticks), do: %{ticksNumber: ticks}
  defp parse_ticks_param(ticks) when is_binary(ticks), do: %{ticksString: ticks}
end
