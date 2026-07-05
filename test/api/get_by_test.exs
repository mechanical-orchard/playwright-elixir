defmodule Playwright.GetByTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Locator, Page}

  describe "get_by_test_id/2" do
    test "locates element by data-testid", %{page: page} do
      Page.set_content(page, ~s|<button data-testid="submit-btn">Submit</button>|)
      locator = Page.get_by_test_id(page, "submit-btn")
      assert Locator.text_content(locator) == "Submit"
    end

    test "locates element with special characters in testid", %{page: page} do
      Page.set_content(page, ~s|<div data-testid="user-profile-123">Profile</div>|)
      locator = Page.get_by_test_id(page, "user-profile-123")
      assert Locator.text_content(locator) == "Profile"
    end
  end

  describe "get_by_label/3" do
    test "locates input by label text (implicit association)", %{page: page} do
      Page.set_content(page, ~s|<label>Email<input type="email" /></label>|)
      locator = Page.get_by_label(page, "Email")
      assert Locator.count(locator) == 1
    end

    test "locates input by label text (explicit for association)", %{page: page} do
      Page.set_content(page, ~s|<label for="email-input">Email</label><input id="email-input" type="email" />|)
      locator = Page.get_by_label(page, "Email")
      assert Locator.count(locator) == 1
    end

    test "with exact option matches only exact text", %{page: page} do
      Page.set_content(
        page,
        ~s|<label>Email Address<input id="full" /></label><label>Email<input id="short" /></label>|
      )

      locator = Page.get_by_label(page, "Email", %{exact: true})
      assert Locator.count(locator) == 1
      assert Locator.get_attribute(locator, "id") == "short"
    end

    test "without exact option matches partial text", %{page: page} do
      Page.set_content(
        page,
        ~s|<label>Email Address<input /></label><label>Email<input /></label>|
      )

      locator = Page.get_by_label(page, "Email")
      assert Locator.count(locator) == 2
    end
  end

  describe "get_by_role/3" do
    test "locates element by role", %{page: page} do
      Page.set_content(page, ~s|<button>Click me</button>|)
      locator = Page.get_by_role(page, "button")
      assert Locator.text_content(locator) == "Click me"
    end

    test "filters by name option", %{page: page} do
      Page.set_content(page, ~s|<button>OK</button><button>Cancel</button>|)
      locator = Page.get_by_role(page, "button", %{name: "OK"})
      assert Locator.count(locator) == 1
      assert Locator.text_content(locator) == "OK"
    end

    test "filters by disabled state", %{page: page} do
      Page.set_content(page, ~s|<button>OK</button><button disabled>Cancel</button>|)
      locator = Page.get_by_role(page, "button", %{disabled: true})
      assert Locator.text_content(locator) == "Cancel"
    end

    test "locates headings by level", %{page: page} do
      Page.set_content(page, ~s|<h1>Title</h1><h2>Subtitle</h2><h3>Section</h3>|)
      locator = Page.get_by_role(page, "heading", %{level: 2})
      assert Locator.text_content(locator) == "Subtitle"
    end

    test "locates link by name", %{page: page} do
      Page.set_content(page, ~s|<a href="/home">Home</a><a href="/about">About</a>|)
      locator = Page.get_by_role(page, "link", %{name: "About"})
      assert Locator.get_attribute(locator, "href") == "/about"
    end

    test "filters by checked state", %{page: page} do
      Page.set_content(
        page,
        ~s|<input type="checkbox" id="a"><input type="checkbox" id="b" checked>|
      )

      locator = Page.get_by_role(page, "checkbox", %{checked: true})
      assert Locator.get_attribute(locator, "id") == "b"
    end
  end

  describe "chaining getBy methods" do
    test "chains getBy methods on Page then Locator", %{page: page} do
      Page.set_content(page, ~s|
        <div data-testid="form">
          <button>Submit</button>
          <button>Cancel</button>
        </div>
        <div>
          <button>Other</button>
        </div>
      |)

      locator =
        page
        |> Page.get_by_test_id("form")
        |> Locator.get_by_role("button", %{name: "Submit"})

      assert Locator.text_content(locator) == "Submit"
    end

    test "chains multiple getBy methods on Locator", %{page: page} do
      Page.set_content(page, ~s|
        <section data-testid="users">
          <div data-testid="user-1">
            <button>Edit</button>
          </div>
          <div data-testid="user-2">
            <button>Edit</button>
          </div>
        </section>
      |)

      locator =
        page
        |> Page.get_by_test_id("users")
        |> Locator.get_by_test_id("user-1")
        |> Locator.get_by_role("button")

      assert Locator.count(locator) == 1
    end
  end

  describe "Frame.get_by_* methods" do
    test "get_by_test_id works on frame", %{page: page} do
      Page.set_content(page, ~s|<span data-testid="main">Frame content</span>|)
      frame = Page.main_frame(page)
      locator = Playwright.Frame.get_by_test_id(frame, "main")
      assert Locator.text_content(locator) == "Frame content"
    end

    test "get_by_label works on frame", %{page: page} do
      Page.set_content(page, ~s|<label>Username<input /></label>|)
      frame = Page.main_frame(page)
      locator = Playwright.Frame.get_by_label(frame, "Username")
      assert Locator.count(locator) == 1
    end

    test "get_by_role works on frame", %{page: page} do
      Page.set_content(page, ~s|<nav><a href="/">Home</a></nav>|)
      frame = Page.main_frame(page)
      locator = Playwright.Frame.get_by_role(frame, "navigation")
      assert Locator.count(locator) == 1
    end
  end

  describe "get_by_placeholder/3" do
    test "locates input by placeholder text", %{page: page} do
      Page.set_content(page, ~s|<input placeholder="Enter your email" />|)
      locator = Page.get_by_placeholder(page, "Enter your email")
      assert Locator.count(locator) == 1
    end

    test "locates input with partial placeholder match", %{page: page} do
      Page.set_content(page, ~s|<input placeholder="Enter your email address" />|)
      locator = Page.get_by_placeholder(page, "email")
      assert Locator.count(locator) == 1
    end

    test "with exact option matches only exact text", %{page: page} do
      Page.set_content(
        page,
        ~s|<input id="full" placeholder="Enter email" /><input id="short" placeholder="email" />|
      )

      locator = Page.get_by_placeholder(page, "email", %{exact: true})
      assert Locator.count(locator) == 1
      assert Locator.get_attribute(locator, "id") == "short"
    end

    test "works on Frame", %{page: page} do
      Page.set_content(page, ~s|<input placeholder="Search..." />|)
      frame = Page.main_frame(page)
      locator = Playwright.Frame.get_by_placeholder(frame, "Search")
      assert Locator.count(locator) == 1
    end

    test "works on Locator", %{page: page} do
      Page.set_content(page, ~s|
        <form data-testid="login">
          <input placeholder="Username" />
          <input placeholder="Password" type="password" />
        </form>
      |)

      locator =
        page
        |> Page.get_by_test_id("login")
        |> Locator.get_by_placeholder("Password")

      assert Locator.count(locator) == 1
    end
  end

  describe "get_by_alt_text/3" do
    test "locates image by alt text", %{page: page} do
      Page.set_content(page, ~s|<img src="logo.png" alt="Company Logo" />|)
      locator = Page.get_by_alt_text(page, "Company Logo")
      assert Locator.count(locator) == 1
    end

    test "locates image with partial alt text match", %{page: page} do
      Page.set_content(page, ~s|<img src="logo.png" alt="Acme Corporation Logo" />|)
      locator = Page.get_by_alt_text(page, "Acme")
      assert Locator.count(locator) == 1
    end

    test "with exact option matches only exact text", %{page: page} do
      Page.set_content(
        page,
        ~s|<img id="full" alt="Logo Image" /><img id="short" alt="Logo" />|
      )

      locator = Page.get_by_alt_text(page, "Logo", %{exact: true})
      assert Locator.count(locator) == 1
      assert Locator.get_attribute(locator, "id") == "short"
    end

    test "works on Frame", %{page: page} do
      Page.set_content(page, ~s|<img alt="Profile Picture" />|)
      frame = Page.main_frame(page)
      locator = Playwright.Frame.get_by_alt_text(frame, "Profile")
      assert Locator.count(locator) == 1
    end

    test "works on Locator", %{page: page} do
      Page.set_content(page, ~s|
        <div data-testid="gallery">
          <img alt="Photo 1" />
          <img alt="Photo 2" />
        </div>
      |)

      locator =
        page
        |> Page.get_by_test_id("gallery")
        |> Locator.get_by_alt_text("Photo 1")

      assert Locator.count(locator) == 1
    end
  end

  describe "get_by_title/3" do
    test "locates element by title attribute", %{page: page} do
      Page.set_content(page, ~s|<button title="Submit form">Submit</button>|)
      locator = Page.get_by_title(page, "Submit form")
      assert Locator.text_content(locator) == "Submit"
    end

    test "locates element with partial title match", %{page: page} do
      Page.set_content(page, ~s|<span title="Click here to learn more">Info</span>|)
      locator = Page.get_by_title(page, "learn more")
      assert Locator.count(locator) == 1
    end

    test "with exact option matches only exact text", %{page: page} do
      Page.set_content(
        page,
        ~s|<span id="full" title="Help text here">A</span><span id="short" title="Help">B</span>|
      )

      locator = Page.get_by_title(page, "Help", %{exact: true})
      assert Locator.count(locator) == 1
      assert Locator.get_attribute(locator, "id") == "short"
    end

    test "works on Frame", %{page: page} do
      Page.set_content(page, ~s|<abbr title="HyperText Markup Language">HTML</abbr>|)
      frame = Page.main_frame(page)
      locator = Playwright.Frame.get_by_title(frame, "HyperText")
      assert Locator.count(locator) == 1
    end

    test "works on Locator", %{page: page} do
      Page.set_content(page, ~s|
        <div data-testid="toolbar">
          <button title="Bold">B</button>
          <button title="Italic">I</button>
        </div>
      |)

      locator =
        page
        |> Page.get_by_test_id("toolbar")
        |> Locator.get_by_title("Bold")

      assert Locator.text_content(locator) == "B"
    end
  end
end
