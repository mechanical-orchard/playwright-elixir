defmodule Playwright.MouseTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Mouse, Page}

  describe "Mouse.click/4" do
    test "clicks at coordinates", %{page: page} do
      Page.set_content(page, """
        <button onclick="window.clicked=true;" style="width:100px;height:100px;">Click</button>
      """)

      Mouse.click(page, 50, 50)

      result = Page.evaluate(page, "() => window.clicked")
      assert result == true
    end

    test "clicks with right button", %{page: page} do
      Page.set_content(page, """
        <div style="width:100px;height:100px;background:red;"
             oncontextmenu="window.rightClicked=true;return false;"></div>
      """)

      Mouse.click(page, 50, 50, button: "right")

      result = Page.evaluate(page, "() => window.rightClicked")
      assert result == true
    end
  end

  describe "Mouse.dblclick/4" do
    test "double-clicks at coordinates", %{page: page} do
      Page.set_content(page, """
        <div style="width:100px;height:100px;background:red;"
             ondblclick="window.dblClicked=true;"></div>
      """)

      Mouse.dblclick(page, 50, 50)

      result = Page.evaluate(page, "() => window.dblClicked")
      assert result == true
    end
  end

  describe "Mouse.move/4" do
    test "moves mouse to coordinates", %{page: page} do
      Page.set_content(page, """
        <div style="width:200px;height:200px;background:red;"
             onmousemove="window.lastMove={x:event.clientX,y:event.clientY};"></div>
      """)

      Mouse.move(page, 100, 100)

      result = Page.evaluate(page, "() => window.lastMove")
      x = Map.get(result, :x) || Map.get(result, "x")
      y = Map.get(result, :y) || Map.get(result, "y")
      assert x == 100
      assert y == 100
    end
  end

  describe "Mouse.down/2 and Mouse.up/2" do
    test "dispatches mousedown and mouseup events", %{page: page} do
      Page.set_content(page, """
        <div style="width:100px;height:100px;background:red;"
             onmousedown="window.mouseDown=true;"
             onmouseup="window.mouseUp=true;"></div>
      """)

      Mouse.move(page, 50, 50)
      Mouse.down(page)

      assert Page.evaluate(page, "() => window.mouseDown") == true

      Mouse.up(page)

      assert Page.evaluate(page, "() => window.mouseUp") == true
    end
  end

  describe "Mouse.wheel/3" do
    test "scrolls the page", %{page: page} do
      Page.set_content(page, """
        <div style="width:100px;height:2000px;background:linear-gradient(red,blue);"></div>
      """)

      initial_scroll = Page.evaluate(page, "() => window.scrollY")
      Mouse.wheel(page, 0, 100)
      # Give browser time to process scroll
      Process.sleep(100)
      final_scroll = Page.evaluate(page, "() => window.scrollY")

      assert final_scroll > initial_scroll
    end
  end
end
