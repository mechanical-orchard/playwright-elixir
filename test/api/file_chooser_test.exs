defmodule Playwright.FileChooserTest do
  use Playwright.TestCase, async: true
  alias Playwright.{FileChooser, Page}
  alias Playwright.SDK.Channel.Event

  describe "FileChooser" do
    test "set_files with single file", %{page: page} do
      Page.set_content(page, "<input type='file' id='upload'>")

      path = Path.join(System.tmp_dir!(), "test-upload-#{:rand.uniform(100_000)}.txt")
      File.write!(path, "test content")

      test_pid = self()

      try do
        Page.on(page, :file_chooser, fn %Event{} = event ->
          Task.start(fn ->
            file_chooser = FileChooser.from_event(event)
            FileChooser.set_files(file_chooser, path)
            send(test_pid, :files_set)
          end)
        end)

        Page.click(page, "#upload")

        assert_receive :files_set, 5000

        # Verify file was set
        value = Page.evaluate(page, "document.querySelector('#upload').files[0]?.name")
        assert value == Path.basename(path)
      after
        File.rm(path)
      end
    end

    test "set_files with multiple files", %{page: page} do
      Page.set_content(page, "<input type='file' id='upload' multiple>")

      path1 = Path.join(System.tmp_dir!(), "test1-#{:rand.uniform(100_000)}.txt")
      path2 = Path.join(System.tmp_dir!(), "test2-#{:rand.uniform(100_000)}.txt")
      File.write!(path1, "content 1")
      File.write!(path2, "content 2")

      test_pid = self()

      try do
        Page.on(page, :file_chooser, fn %Event{} = event ->
          Task.start(fn ->
            file_chooser = FileChooser.from_event(event)
            FileChooser.set_files(file_chooser, [path1, path2])
            send(test_pid, :files_set)
          end)
        end)

        Page.click(page, "#upload")

        assert_receive :files_set, 5000

        count = Page.evaluate(page, "document.querySelector('#upload').files.length")
        assert count == 2
      after
        File.rm(path1)
        File.rm(path2)
      end
    end

    test "is_multiple returns false for single file input", %{page: page} do
      Page.set_content(page, "<input type='file' id='upload'>")

      test_pid = self()

      Page.on(page, :file_chooser, fn %Event{} = event ->
        Task.start(fn ->
          file_chooser = FileChooser.from_event(event)
          send(test_pid, {:is_multiple, FileChooser.is_multiple(file_chooser)})
        end)
      end)

      Page.click(page, "#upload")

      assert_receive {:is_multiple, is_multiple}, 5000
      assert is_multiple == false
    end

    test "is_multiple returns true for multiple file input", %{page: page} do
      Page.set_content(page, "<input type='file' id='upload' multiple>")

      test_pid = self()

      Page.on(page, :file_chooser, fn %Event{} = event ->
        Task.start(fn ->
          file_chooser = FileChooser.from_event(event)
          send(test_pid, {:is_multiple, FileChooser.is_multiple(file_chooser)})
        end)
      end)

      Page.click(page, "#upload")

      assert_receive {:is_multiple, is_multiple}, 5000
      assert is_multiple == true
    end

    test "element returns the input element", %{page: page} do
      Page.set_content(page, "<input type='file' id='upload'>")

      test_pid = self()

      Page.on(page, :file_chooser, fn %Event{} = event ->
        Task.start(fn ->
          file_chooser = FileChooser.from_event(event)
          element = FileChooser.element(file_chooser)
          send(test_pid, {:element, element})
        end)
      end)

      Page.click(page, "#upload")

      assert_receive {:element, element}, 5000
      assert %Playwright.ElementHandle{} = element
    end

    test "page returns the page", %{page: page} do
      Page.set_content(page, "<input type='file' id='upload'>")

      test_pid = self()

      Page.on(page, :file_chooser, fn %Event{} = event ->
        Task.start(fn ->
          file_chooser = FileChooser.from_event(event)
          fc_page = FileChooser.page(file_chooser)
          send(test_pid, {:page, fc_page})
        end)
      end)

      Page.click(page, "#upload")

      assert_receive {:page, fc_page}, 5000
      assert fc_page.guid == page.guid
    end

    test "set_files with file payload", %{page: page} do
      Page.set_content(page, "<input type='file' id='upload'>")

      test_pid = self()

      Page.on(page, :file_chooser, fn %Event{} = event ->
        Task.start(fn ->
          file_chooser = FileChooser.from_event(event)

          FileChooser.set_files(file_chooser, %{
            name: "test-payload.txt",
            mimeType: "text/plain",
            buffer: Base.encode64("Hello from payload")
          })

          send(test_pid, :files_set)
        end)
      end)

      Page.click(page, "#upload")

      assert_receive :files_set, 5000

      value = Page.evaluate(page, "document.querySelector('#upload').files[0]?.name")
      assert value == "test-payload.txt"
    end
  end
end
