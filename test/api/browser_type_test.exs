defmodule Playwright.BrowserTypeTest do
  use Playwright.TestCase, async: true

  # BrowserType.connect/2
  # - test_browser_type_connect_should_be_able_to_reconnect_to_a_browser
  # - test_browser_type_connect_should_be_able_to_connect_two_browsers_at_the_same_time
  # - test_browser_type_connect_disconnected_event_should_be_emitted_when_browser_is_closed_or_server_is_closed
  # - test_browser_type_connect_disconnected_event_should_be_emitted_when_remote_killed_connection
  # - test_browser_type_disconnected_event_should_have_browser_as_argument
  # - test_browser_type_connect_set_browser_connected_state
  # - test_browser_type_connect_should_throw_when_used_after_is_connected_returns_false
  # - test_browser_type_connect_should_reject_navigation_when_browser_closes
  # - test_should_not_allow_getting_the_path
  # - test_prevent_getting_video_path
  # - test_connect_to_closed_server_without_hangs

  # BrowserType.connect_over_cdp/3
  # - test_connect_to_an_existing_cdp_session
  # - test_connect_to_an_existing_cdp_session_twice
  # - test_conect_over_a_ws_endpoint

  # BrowserType.launch/2
  # - test_browser_type_launch_should_reject_all_promises_when_browser_is_closed
  # - test_browser_type_launch_should_throw_if_page_argument_is_passed
  # - test_browser_type_launch_should_reject_if_launched_browser_fails_immediately
  # - test_browser_type_launch_should_reject_if_executable_path_is_invalid
  # - test_browser_type_executable_path_should_work
  # - test_browser_type_name_should_work
  # - test_browser_close_should_fire_close_event_for_all_contexts
  # - test_browser_close_should_be_callable_twice
  # - test_browser_launch_should_return_background_pages
end
