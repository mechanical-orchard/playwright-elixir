defmodule Playwright.BrowserContext.ExpectTest do
  use Playwright.TestCase, async: true
  # alias Playwright.BrowserContext

  describe "BrowserContext.expect_event/2" do

  end
end

# ---

# ---------------------------------------------------------
#
# BrowserContext
# ---
# async def wait_for_event(
#   self, event: str, predicate: Callable = None, timeout: float = None
# ) -> Any:
#   async with self.expect_event(event, predicate, timeout) as event_info:
#       pass
#   return await event_info
# ---
# def expect_event(
#   self,
#   event: str,
#   predicate: Callable = None,
#   timeout: float = None,
# ) -> EventContextManagerImpl:
#   if timeout is None:
#       timeout = self._timeout_settings.timeout()
#   wait_helper = WaitHelper(self, f"browser_context.expect_event({event})")
#   wait_helper.reject_on_timeout(
#       timeout, f'Timeout while waiting for event "{event}"'
#   )
#   if event != BrowserContext.Events.Close:
#       wait_helper.reject_on_event(
#           self, BrowserContext.Events.Close, Error("Context closed")
#       )
#   wait_helper.wait_for_event(self, event, predicate)
#   return EventContextManagerImpl(wait_helper.result())
#
# WaitHelper
# ---
# def wait_for_event(
#   self,
#   emitter: EventEmitter,
#   event: str,
#   predicate: Callable = None,
# ) -> None:
#   def listener(event_data: Any = None) -> None:
#       if not predicate or predicate(event_data):
#           self._fulfill(event_data)
#
#   emitter.on(event, listener)
#   self._registered_listeners.append((emitter, event, listener))
