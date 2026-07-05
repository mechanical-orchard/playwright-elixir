defmodule Playwright.PdfTest do
  use Playwright.TestCase, async: true
  alias Playwright.Page

  describe "Page.pdf/2" do
    test "returns PDF binary", %{page: page} do
      Page.set_content(page, "<h1>Hello PDF</h1>")

      result = Page.pdf(page)

      # PDF files start with %PDF
      assert String.starts_with?(Base.decode64!(result), "%PDF")
    end

    test "saves to path", %{page: page} do
      Page.set_content(page, "<h1>Hello PDF</h1>")
      path = Path.join(System.tmp_dir!(), "test-#{:rand.uniform(10000)}.pdf")

      try do
        Page.pdf(page, %{path: path})

        assert File.exists?(path)
        assert String.starts_with?(File.read!(path), "%PDF")
      after
        File.rm(path)
      end
    end

    test "with format option", %{page: page} do
      Page.set_content(page, "<h1>Hello PDF</h1>")

      result = Page.pdf(page, %{format: "A4"})

      assert String.starts_with?(Base.decode64!(result), "%PDF")
    end

    test "with landscape option", %{page: page} do
      Page.set_content(page, "<h1>Hello PDF</h1>")

      result = Page.pdf(page, %{landscape: true})

      assert String.starts_with?(Base.decode64!(result), "%PDF")
    end

    test "with print_background option", %{page: page} do
      Page.set_content(page, ~s|<div style="background: red; width: 100%; height: 100%;">Hello</div>|)

      result = Page.pdf(page, %{print_background: true})

      assert String.starts_with?(Base.decode64!(result), "%PDF")
    end
  end
end
