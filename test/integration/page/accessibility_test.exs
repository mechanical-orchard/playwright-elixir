defmodule Playwright.Page.AccessibilityTest do
  use Playwright.TestCase, async: true
  # doctest Playwright.Page.Accessibility

  alias Playwright.Page

  describe "Accessibility.snapshot/1" do
    # until Page.wait_for_function is implemented
    @tag :skip
    test "snapshots", %{page: page} do
      page
      |> Page.set_content("""
      <head>
        <title>Accessibility Test</title>
      </head>
      <body>
        <h1>Inputs</h1>
        <input placeholder="Empty input" autofocus />
        <input placeholder="readonly input" readonly />
        <input placeholder="disabled input" disabled />
        <input aria-label="Input with whitespace" value="  " />
        <input value="value only" />
        <input aria-placeholder="placeholder" value="and a value" />
        <div aria-hidden="true" id="desc">This is a description!</div>
        <input aria-placeholder="placeholder" value="and a value" aria-describedby="desc" />
      </body>
      """)

      # > Autofocus happens after a delay in chrome.
      # Page.wait_for_function(page, "document.activeElement.hasAttribute('autofocus')")
      # Page.expect_function(page, "document.activeElement.hasAttribute('autofocus')")
      assert Page.Accessibility.snapshot(page) == %{
               role: "WebArea",
               name: "Accessibility Test",
               children: [
                 %{role: "heading", name: "Inputs", level: 1},
                 %{role: "textbox", name: "Empty input", focused: true},
                 %{role: "textbox", name: "readonly input", readonly: true},
                 %{role: "textbox", name: "disabled input", disabled: true},
                 %{role: "textbox", name: "Input with whitespace", value: "  "},
                 %{role: "textbox", name: "", value: "value only"},
                 %{role: "textbox", name: "placeholder", value: "and a value"},
                 %{role: "textbox", name: "placeholder", value: "and a value", description: "This is a description!"}
               ]
             }
    end

    test "with regular text", %{page: page} do
      Page.set_content(page, "<div>Hello World</div>")

      [element | _] = Page.Accessibility.snapshot(page).children
      assert element == %{role: "text", name: "Hello World"}
    end

    test "with ARIA roledescription", %{page: page} do
      Page.set_content(page, "<p tabIndex=-1 aria-roledescription='foo'>Hi</p>")

      [element | _] = Page.Accessibility.snapshot(page).children
      assert element.roledescription == "foo"
    end

    test "with ARIA orientation", %{page: page} do
      Page.set_content(page, "<a href='' role='slider' aria-orientation='vertical'>11</a>")

      [element | _] = Page.Accessibility.snapshot(page).children
      assert element.orientation == "vertical"
    end

    test "with ARIA autocomplete", %{page: page} do
      Page.set_content(page, "<div role='textbox' aria-autocomplete='list'>hi</div>")

      [element | _] = Page.Accessibility.snapshot(page).children
      assert element.autocomplete == "list"
    end

    test "with ARIA multiselectable", %{page: page} do
      Page.set_content(page, "<div role='grid' tabIndex=-1 aria-multiselectable=true>hey</div>")

      [element | _] = Page.Accessibility.snapshot(page).children
      assert element.multiselectable == true
    end

    test "with ARIA keyshortcuts", %{page: page} do
      Page.set_content(page, "<div role='grid' tabIndex=-1 aria-keyshortcuts='foo'>hey</div>")

      [element | _] = Page.Accessibility.snapshot(page).children
      assert element.keyshortcuts == "foo"
    end

    test "with a <title>", %{page: page} do
      Page.set_content(page, """
      <title>This is the title</title>
      <div>This is the content</div>
      """)

      snapshot = Page.Accessibility.snapshot(page)
      assert snapshot.name == "This is the title"

      [content | _] = snapshot.children
      assert content.name == "This is the content"
    end
  end

  describe "page accessibility with filtering children of leaf nodes" do
    test "does not report text nodes inside controls", %{page: page} do
      Page.set_content(page, """
      <div role="tablist">
        <div role="tab" aria-selected="true"><b>Tab1</b></div>
        <div role="tab">Tab2</div>
      </div>
      """)

      assert Page.Accessibility.snapshot(page) == %{
               role: "WebArea",
               name: "",
               children: [
                 %{role: "tab", name: "Tab1", selected: true},
                 %{role: "tab", name: "Tab2"}
               ]
             }
    end

    test "retains rich text editable fields", %{page: page} do
      Page.set_content(page, """
      <div contenteditable="true">
        Edit this image: <img src="fakeimage.png" alt="my fake image">
      </div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "generic",
               name: "",
               value: "Edit this image: ",
               children: [
                 %{role: "text", name: "Edit this image:"},
                 %{role: "image", name: "my fake image"}
               ]
             }
    end

    test "retains rich text editable fields with role", %{page: page} do
      Page.set_content(page, """
      <div contenteditable="true" role="textbox">
        Edit this image: <img src="fakeimage.png" alt="my fake image">
      </div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "textbox",
               name: "",
               multiline: true,
               value: "Edit this image: ",
               children: [
                 %{role: "text", name: "Edit this image:"},
                 %{role: "image", name: "my fake image"}
               ]
             }
    end

    test "excludes children from plain text editable fields with role", %{page: page} do
      Page.set_content(page, """
      <div contenteditable="plaintext-only" role="textbox">Edit this image: <img src="fakeimage.png" alt="my fake image"></div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "textbox",
               name: "",
               multiline: true,
               value: "Edit this image: "
             }
    end

    test "excludes content from plain text editable fields without role", %{page: page} do
      Page.set_content(page, """
      <div contenteditable="plaintext-only">Edit this image: <img src="fakeimage.png" alt="my fake image"></div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "generic",
               name: "",
               value: "Edit this image: "
             }
    end

    test "excludes content from plain text editable fields with tabindex and without role", %{page: page} do
      Page.set_content(page, """
      <div contenteditable="plaintext-only" tabIndex=0>Edit this image: <img src="fakeimage.png" alt="my fake image"></div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "generic",
               name: "",
               value: "Edit this image: "
             }
    end

    test "excludes children from non-editable textbox with role, tabindex and label", %{page: page} do
      Page.set_content(page, """
      <div role="textbox" tabIndex=0 aria-checked="true" aria-label="my favorite textbox">
        this is the inner content
        <img alt="yo" src="fakeimg.png">
      </div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "textbox",
               name: "my favorite textbox",
               value: "this is the inner content "
             }
    end

    test "excludes children from a checkbox with tabindex and label", %{page: page} do
      Page.set_content(page, """
      <div role="checkbox" tabIndex=0 aria-checked="true" aria-label="my favorite checkbox">
        this is the inner content
        <img alt="yo" src="fakeimg.png">
      </div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "checkbox",
               name: "my favorite checkbox",
               checked: true
             }
    end

    test "excludes children from a checkbox without a label", %{page: page} do
      Page.set_content(page, """
      <div role="checkbox" aria-checked="true">
        this is the inner content
        <img alt="yo" src="fakeimg.png">
      </div>
      """)

      [element | _] = Page.Accessibility.snapshot(page).children

      assert element == %{
               role: "checkbox",
               name: "this is the inner content yo",
               checked: true
             }
    end
  end

  describe "page accessibility scoped via :root" do
    test "with a button", %{page: page} do
      Page.set_content(page, "<button>My Button</button>")

      element = Page.query_selector(page, "button")

      assert Page.Accessibility.snapshot(page, %{root: element}) == %{
               role: "button",
               name: "My Button"
             }
    end

    test "with an input", %{page: page} do
      Page.set_content(page, "<input title='My Input' value='My Value'>")

      element = Page.query_selector(page, "input")

      assert Page.Accessibility.snapshot(page, %{root: element}) == %{
               role: "textbox",
               name: "My Input",
               value: "My Value"
             }
    end

    test "with a menu", %{page: page} do
      Page.set_content(page, """
      <div role="menu" title="My Menu">
        <div role="menuitem">First Item</div>
        <div role="menuitem">Second Item</div>
        <div role="menuitem">Third Item</div>
      </div>
      """)

      element = Page.query_selector(page, "div[role='menu']")

      assert Page.Accessibility.snapshot(page, %{root: element}) == %{
               role: "menu",
               name: "My Menu",
               children: [
                 %{role: "menuitem", name: "First Item"},
                 %{role: "menuitem", name: "Second Item"},
                 %{role: "menuitem", name: "Third Item"}
               ],
               orientation: "vertical"
             }
    end

    test "when the DOM node is removed, returns nil", %{page: page} do
      Page.set_content(page, "<button>My Button</button>")

      element = Page.query_selector(page, "button")
      Page.eval_on_selector(page, "button", "button => button.remove()")

      refute Page.Accessibility.snapshot(page, %{root: element})
    end
  end

  describe "additional snapshot options" do
    test "requesting 'uninteresting' nodes", %{page: page} do
      Page.set_content(page, """
      <div id="root" role="textbox">
        <div>
          hello
          <div>
            world
          </div>
        </div>
      </div>
      """)

      element = Page.query_selector(page, "#root")
      snapshot = Page.Accessibility.snapshot(page, %{root: element, interesting_only: false})
      assert snapshot.role == "textbox"
      assert String.contains?(snapshot.value, "hello")
      assert String.contains?(snapshot.value, "world")
      assert snapshot.children
    end
  end
end
