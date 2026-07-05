defmodule Playwright.DialogTest do
  use Playwright.TestCase, async: true
  alias Playwright.{Dialog, Page}
  alias Playwright.SDK.Channel.Event

  describe "Dialog.accept/1" do
    test "accepts an alert dialog", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        # Spawn a task to handle dialog to avoid deadlock with Connection GenServer
        Task.start(fn ->
          send(test_pid, {:dialog_type, Dialog.type(dialog)})
          send(test_pid, {:dialog_message, Dialog.message(dialog)})
          Dialog.accept(dialog)
          send(test_pid, :dialog_handled)
        end)
      end)

      Page.evaluate(page, "() => alert('Hello!')")
      assert_receive({:dialog_type, "alert"}, 5000)
      assert_receive({:dialog_message, "Hello!"}, 5000)
      assert_receive(:dialog_handled, 5000)
    end

    test "accepts a confirm dialog returning true", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        Task.start(fn ->
          send(test_pid, {:dialog_type, Dialog.type(dialog)})
          Dialog.accept(dialog)
          send(test_pid, :dialog_handled)
        end)
      end)

      task =
        Task.async(fn ->
          Page.evaluate(page, "() => confirm('Accept?')")
        end)

      assert_receive({:dialog_type, "confirm"}, 5000)
      assert_receive(:dialog_handled, 5000)
      result = Task.await(task)
      assert result == true
    end
  end

  describe "Dialog.dismiss/1" do
    test "dismisses a confirm dialog returning false", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        Task.start(fn ->
          Dialog.dismiss(dialog)
          send(test_pid, :dialog_handled)
        end)
      end)

      task =
        Task.async(fn ->
          Page.evaluate(page, "() => confirm('Accept?')")
        end)

      assert_receive(:dialog_handled, 5000)
      result = Task.await(task)
      assert result == false
    end
  end

  describe "Dialog.accept/2 with prompt" do
    test "accepts a prompt with text", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        Task.start(fn ->
          send(test_pid, {:dialog_type, Dialog.type(dialog)})
          send(test_pid, {:default_value, Dialog.default_value(dialog)})
          Dialog.accept(dialog, "my input")
          send(test_pid, :dialog_handled)
        end)
      end)

      task =
        Task.async(fn ->
          Page.evaluate(page, "() => prompt('Enter:', 'default')")
        end)

      assert_receive({:dialog_type, "prompt"}, 5000)
      assert_receive({:default_value, "default"}, 5000)
      assert_receive(:dialog_handled, 5000)
      result = Task.await(task)
      assert result == "my input"
    end

    test "accepts a prompt without text uses empty string", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        Task.start(fn ->
          Dialog.accept(dialog)
          send(test_pid, :dialog_handled)
        end)
      end)

      task =
        Task.async(fn ->
          Page.evaluate(page, "() => prompt('Enter:', 'default value')")
        end)

      assert_receive(:dialog_handled, 5000)
      result = Task.await(task)
      # When accepting without text, Playwright uses empty string, not default
      assert result == ""
    end
  end

  describe "Dialog properties" do
    test "message/1 returns dialog message", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        Task.start(fn ->
          send(test_pid, {:message, Dialog.message(dialog)})
          Dialog.accept(dialog)
        end)
      end)

      Page.evaluate(page, "() => alert('Test message')")
      assert_receive({:message, "Test message"}, 5000)
    end

    test "type/1 returns dialog type", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        Task.start(fn ->
          send(test_pid, {:type, Dialog.type(dialog)})
          Dialog.accept(dialog)
        end)
      end)

      Page.evaluate(page, "() => alert('Test')")
      assert_receive({:type, "alert"}, 5000)
    end

    test "default_value/1 returns prompt default", %{page: page} do
      test_pid = self()

      Page.on(page, :dialog, fn %Event{params: %{dialog: dialog}} ->
        Task.start(fn ->
          send(test_pid, {:default_value, Dialog.default_value(dialog)})
          Dialog.accept(dialog)
        end)
      end)

      Page.evaluate(page, "() => prompt('Enter:', 'default value')")
      assert_receive({:default_value, "default value"}, 5000)
    end
  end
end
