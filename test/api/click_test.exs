defmodule Playwright.ClickTest do
  use Playwright.TestCase, async: true
  alias Playwright.{ElementHandle, Frame, Page}

  describe "Frame.click/3" do
    test "with a button inside an iframe", %{assets: assets, page: page} do
      :ok = Page.set_content(page, "<div style='width:100px; height:100px'>spacer</div>")
      frame = attach_frame(page, "button-test", assets.prefix <> "/input/button.html")
      %ElementHandle{} = button = Frame.query_selector(frame, "button")

      assert ElementHandle.click(button) == :ok
      assert Frame.evaluate(frame, "window.result") == "Clicked"
    end
  end

  describe "Page.click/3" do
    test "returns 'subject'", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")
      assert %Page{} = Page.click(page, "button")
    end

    test "with a button", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")
      Page.click(page, "button")
      assert Page.evaluate(page, "result") == "Clicked"
    end
  end

  describe "Page.dblclick/2, mimicking Python tests" do
    test "returns 'subject'", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")
      assert %Page{} = Page.dblclick(page, "button")
    end

    test "test_locators.py: `test_double_click_the_button`", %{assets: assets, page: page} do
      Page.goto(page, assets.prefix <> "/input/button.html")

      Page.evaluate(page, """
        () => {
          window['double'] = false;
          const button = document.querySelector('button');
          button.addEventListener('dblclick', event => {
            window['double'] = true;
          });
        }
      """)

      assert Page.dblclick(page, "button") == :ok
      assert Page.evaluate(page, "window['double']") == true
      assert Page.evaluate(page, "window['result']") == "Clicked"
    end
  end
end

# async def test_click_the_button(page, server):
# async def test_click_svg(page, server):
# async def test_click_the_button_if_window_node_is_removed(page, server):
# async def test_click_on_a_span_with_an_inline_element_inside(page, server):
# async def test_click_not_throw_when_page_closes(browser, server):
# async def test_click_the_button_after_navigation(page, server):
# async def test_click_the_button_after_a_cross_origin_navigation_(page, server):
# async def test_click_with_disabled_javascript(browser, server):
# async def test_click_when_one_of_inline_box_children_is_outside_of_viewport(
# async def test_select_the_text_by_triple_clicking(page, server):
# async def test_click_offscreen_buttons(page, server):
# async def test_waitFor_visible_when_already_visible(page, server):
# async def test_wait_with_force(page, server):
# async def test_wait_for_display_none_to_be_gone(page, server):
# async def test_wait_for_visibility_hidden_to_be_gone(page, server):
# async def test_timeout_waiting_for_display_none_to_be_gone(page, server):
# async def test_timeout_waiting_for_visbility_hidden_to_be_gone(page, server):
# async def test_waitFor_visible_when_parent_is_hidden(page, server):
# async def test_click_wrapped_links(page, server):
# async def test_click_on_checkbox_input_and_toggle(page, server):
# async def test_click_on_checkbox_label_and_toggle(page, server):
# async def test_not_hang_with_touch_enabled_viewports(playwright, server, browser):
# async def test_scroll_and_click_the_button(page, server):
# async def test_double_click_the_button(page, server):
# async def test_click_a_partially_obscured_button(page, server):
# async def test_click_a_rotated_button(page, server):
# async def test_fire_contextmenu_event_on_right_click(page, server):
# async def test_click_links_which_cause_navigation(page, server):
# async def test_click_the_button_with_device_scale_factor_set(browser, server, utils):
# async def test_click_the_button_with_px_border_with_offset(page, server, is_webkit):
# async def test_click_the_button_with_em_border_with_offset(page, server, is_webkit):
# async def test_click_a_very_large_button_with_offset(page, server, is_webkit):
# async def test_click_a_button_in_scrolling_container_with_offset(
# async def test_click_the_button_with_offset_with_page_scale(
# async def test_wait_for_stable_position(page, server):
# async def test_timeout_waiting_for_stable_position(page, server):
# async def test_wait_for_becoming_hit_target(page, server):
# async def test_timeout_waiting_for_hit_target(page, server):
# async def test_fail_when_obscured_and_not_waiting_for_hit_target(page, server):
# async def test_wait_for_button_to_be_enabled(page, server):
# async def test_timeout_waiting_for_button_to_be_enabled(page, server):
# async def test_wait_for_input_to_be_enabled(page, server):
# async def test_wait_for_select_to_be_enabled(page, server):
# async def test_click_disabled_div(page, server):
# async def test_climb_dom_for_inner_label_with_pointer_events_none(page, server):
# async def test_climb_up_to_role_button(page, server):
# async def test_wait_for_BUTTON_to_be_clickable_when_it_has_pointer_events_none(
# async def test_wait_for_LABEL_to_be_clickable_when_it_has_pointer_events_none(
# async def test_update_modifiers_correctly(page, server):
# async def test_click_an_offscreen_element_when_scroll_behavior_is_smooth(page):
# async def test_report_nice_error_when_element_is_detached_and_force_clicked(
# async def test_fail_when_element_detaches_after_animation(page, server):
# async def test_retry_when_element_detaches_after_animation(page, server):
# async def test_retry_when_element_is_animating_from_outside_the_viewport(page, server):
# async def test_fail_when_element_is_animating_from_outside_the_viewport_with_force(
# async def test_not_retarget_when_element_changes_on_hover(page, server):
# async def test_not_retarget_when_element_is_recycled_on_hover(page, server):
# async def test_click_the_button_when_window_inner_width_is_corrupted(page, server):
# async def test_timeout_when_click_opens_alert(page, server):
# async def test_check_the_box(page):
# async def test_not_check_the_checked_box(page):
# async def test_uncheck_the_box(page):
# async def test_not_uncheck_the_unchecked_box(page):
# async def test_check_the_box_by_label(page):
# async def test_check_the_box_outside_label(page):
# async def test_check_the_box_inside_label_without_id(page):
# async def test_check_radio(page):
# async def test_check_the_box_by_aria_role(page):
