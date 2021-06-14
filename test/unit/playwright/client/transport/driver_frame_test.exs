defmodule Test.Unit.Playwright.Client.Transport.DriverFrameTest do
  use ExUnit.Case
  alias Playwright.Client.Transport.DriverFrame

  describe "parse_frame/4" do
    test "when the frame is only a UTF-32 character (a standalone length padding)" do
      frame = <<15, 0, 0, 0>>

      assert DriverFrame.parse_frame(frame, 0, "", ["accumulated"]) == %{
               messages: ["accumulated"],
               remaining: 15,
               buffer: ""
             }
    end

    test "when the frame contains a single UTF-8 binary, without a read-length padding character (because that was in the previous frame) and the data length is equal to the read-length" do
      read_length = 11
      frame = "new-message"

      assert DriverFrame.parse_frame(frame, read_length, "", ["accumulated"]) == %{
               messages: ["accumulated", "new-message"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame contains a single UTF-8 messsage, prefixed with a UTF-32 read-length padding character" do
      pad = <<11, 0, 0, 0>>
      txt = "new-message"
      frame = pad <> txt

      assert DriverFrame.parse_frame(frame, 0, "", ["accumulated"]) == %{
               messages: ["accumulated", "new-message"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame is 'multi-part' (contains multiple messages), with no read-length prefix" do
      frame = "message-1" <> <<11, 0, 0, 0>> <> "message-two"
      remaining = String.length("message-1")

      assert DriverFrame.parse_frame(frame, remaining, "", ["accumulated"]) == %{
               messages: ["accumulated", "message-1", "message-two"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame is 'multi-part' (contains a couple messages), and includes a read-length prefix" do
      frame = <<9, 0, 0, 0>> <> "message-1" <> <<11, 0, 0, 0>> <> "message-two"

      assert DriverFrame.parse_frame(frame, 0, "", ["accumulated"]) == %{
               messages: ["accumulated", "message-1", "message-two"],
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

      assert DriverFrame.parse_frame(frame, 0, "", []) == %{
               messages: ["message-1", "message-two", "message-three"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when ... <something about a buffer>" do
      frame = "message-1B" <> <<11, 0, 0, 0>> <> "message-two"

      assert DriverFrame.parse_frame(frame, 10, "message-1A", ["accumulated"]) == %{
               messages: ["accumulated", "message-1Amessage-1B", "message-two"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when ... <something about a buffer and some padding>" do
      frame = <<10, 0, 0, 0>> <> "message-1B" <> <<11, 0, 0, 0>> <> "message-two"

      assert DriverFrame.parse_frame(frame, 0, "message-1A", ["accumulated"]) == %{
               messages: ["accumulated", "message-1A", "message-1B", "message-two"],
               remaining: 0,
               buffer: ""
             }
    end

    test "when the frame is a 'partial'" do
      assert DriverFrame.parse_frame("a partial", 51, "", []) == %{
               messages: [],
               remaining: 42,
               buffer: "a partial"
             }
    end
  end
end
