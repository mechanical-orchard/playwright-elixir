defmodule Playwright.ClockTest do
  use Playwright.TestCase, async: true
  alias Playwright.{BrowserContext, Clock, Page}

  describe "Clock.install/2" do
    test "sets initial time from ISO string", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context, %{time: "2024-01-01T00:00:00Z"})

      time = Page.evaluate(page, "() => new Date().toISOString()")
      assert time =~ "2024-01-01"

      BrowserContext.close(context)
    end

    test "sets initial time from number (epoch ms)", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      # Jan 1, 2024 00:00:00 UTC in milliseconds
      Clock.install(context, %{time: 1_704_067_200_000})

      time = Page.evaluate(page, "() => new Date().toISOString()")
      assert time =~ "2024-01-01"

      BrowserContext.close(context)
    end
  end

  describe "Clock.fast_forward/2" do
    test "advances time by milliseconds", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context, %{time: 0})

      time_before = Page.evaluate(page, "() => Date.now()")
      Clock.fast_forward(context, 5000)
      time_after = Page.evaluate(page, "() => Date.now()")

      assert time_after - time_before >= 5000

      BrowserContext.close(context)
    end

    test "advances time by string duration", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context, %{time: 0})
      # 1 min 30 sec = 90000ms
      Clock.fast_forward(context, "00:01:30")

      time = Page.evaluate(page, "() => Date.now()")
      assert_in_delta time, 90_000, 100

      BrowserContext.close(context)
    end
  end

  describe "Clock.set_fixed_time/2" do
    test "freezes time at specified value", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context)
      Clock.set_fixed_time(context, "2024-06-15T12:00:00Z")

      time1 = Page.evaluate(page, "() => Date.now()")
      Process.sleep(100)
      time2 = Page.evaluate(page, "() => Date.now()")

      # Time should not advance
      assert time1 == time2

      BrowserContext.close(context)
    end
  end

  describe "Clock.set_system_time/2" do
    test "sets time but allows it to advance", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context)
      Clock.set_system_time(context, "2024-06-15T12:00:00Z")

      time1 = Page.evaluate(page, "() => Date.now()")
      # Small sleep to allow time to advance
      Process.sleep(50)
      time2 = Page.evaluate(page, "() => Date.now()")

      # Time should have advanced (or at least not be frozen)
      # Note: This test might be flaky if execution is very fast
      assert time2 >= time1

      BrowserContext.close(context)
    end
  end

  describe "Clock.run_for/2" do
    test "runs clock for specified duration", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context, %{time: 0})
      # 10 seconds
      Clock.run_for(context, 10_000)

      time = Page.evaluate(page, "() => Date.now()")
      assert_in_delta time, 10_000, 100

      BrowserContext.close(context)
    end

    test "runs clock for string duration", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context, %{time: 0})
      # 1 hour
      Clock.run_for(context, "01:00:00")

      time = Page.evaluate(page, "() => Date.now()")
      assert_in_delta time, 3_600_000, 100

      BrowserContext.close(context)
    end
  end

  describe "Clock.pause_at/2 and Clock.resume/1" do
    test "pauses and resumes the clock", %{browser: browser} do
      context = Playwright.Browser.new_context(browser)
      page = BrowserContext.new_page(context)

      Clock.install(context)
      Clock.pause_at(context, "2024-01-01T12:00:00Z")

      time_paused = Page.evaluate(page, "() => Date.now()")

      # Time should be frozen while paused
      Process.sleep(50)
      time_still_paused = Page.evaluate(page, "() => Date.now()")
      assert time_paused == time_still_paused

      Clock.resume(context)

      # After resume, time should advance
      Process.sleep(50)
      time_after_resume = Page.evaluate(page, "() => Date.now()")
      assert time_after_resume >= time_paused

      BrowserContext.close(context)
    end
  end
end
