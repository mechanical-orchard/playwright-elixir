defmodule Playwright.SDK.Transport.DriverMessageTest do
  use ExUnit.Case, async: true
  alias Playwright.SDK.Transport.DriverMessage

  describe "parse/4" do
    test "when the frame is only a UTF-32 character (a standalone length padding)" do
      frame = <<15, 0, 0, 0>>

      assert DriverMessage.parse(frame, 0, "", ["accumulated"]) == %{
               frames: ["accumulated"],
               remaining: 15,
               buffer: ""
             }
    end

    test "when the frame contains a single UTF-8 binary, without a read-length padding character (because that was in the previous frame) and the data length is equal to the read-length" do
      read_length = 11
      frame = "new-message"

      assert DriverMessage.parse(frame, read_length, "", ["accumulated"]) == %{
               frames: ["accumulated", "new-message"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame contains a single UTF-8 message, prefixed with a UTF-32 read-length padding character" do
      pad = <<11, 0, 0, 0>>
      txt = "new-message"
      frame = pad <> txt

      assert DriverMessage.parse(frame, 0, "", ["accumulated"]) == %{
               frames: ["accumulated", "new-message"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame is 'multi-part' (contains multiple messages), with no read-length prefix" do
      frame = "message-1" <> <<11, 0, 0, 0>> <> "message-two"
      remaining = String.length("message-1")

      assert DriverMessage.parse(frame, remaining, "", ["accumulated"]) == %{
               frames: ["accumulated", "message-1", "message-two"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame is 'multi-part' (contains a couple messages), and includes a read-length prefix" do
      frame = <<9, 0, 0, 0>> <> "message-1" <> <<11, 0, 0, 0>> <> "message-two"

      assert DriverMessage.parse(frame, 0, "", ["accumulated"]) == %{
               frames: ["accumulated", "message-1", "message-two"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame is 'multi-part' and contains more than a couple messages" do
      frame =
        <<9, 0, 0, 0>> <>
          "message-1" <>
          <<11, 0, 0, 0>> <>
          "message-two" <>
          <<13, 0, 0, 0>> <>
          "message-three"

      assert DriverMessage.parse(frame, 0, "", []) == %{
               frames: ["message-1", "message-two", "message-three"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when ... <something about a buffer>" do
      frame = "message-1B" <> <<11, 0, 0, 0>> <> "message-two"

      assert DriverMessage.parse(frame, 10, "message-1A", ["accumulated"]) == %{
               frames: ["accumulated", "message-1Amessage-1B", "message-two"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when ... <something about a buffer and some padding>" do
      frame = <<10, 0, 0, 0>> <> "message-1B" <> <<11, 0, 0, 0>> <> "message-two"

      assert DriverMessage.parse(frame, 0, "message-1A", ["accumulated"]) == %{
               frames: ["accumulated", "message-1A", "message-1B", "message-two"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame is a 'partial'" do
      assert DriverMessage.parse("a partial", 51, "", []) == %{
               frames: [],
               remaining: 42,
               buffer: "a partial"
             }
    end

    test "when contents include special unicode characters" do
      frame = "ellipsis: …" <> <<13, 0, 0, 0>> <> "carriage: ↵"

      assert DriverMessage.parse(frame, 13, "", []) == %{
               frames: ["ellipsis: …", "carriage: ↵"],
               remaining: 0,
               buffer: ""
             }
    end
  end
end
