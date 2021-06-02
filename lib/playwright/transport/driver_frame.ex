defmodule Playwright.Transport.DriverFrame do
  # NOTE
  # - Frames contain:
  #   - Messages
  #   - Padding (which indicate "read length")

  # API
  # ----------------------------------------------------------------------------

  def parse_frame(<<remaining::utf32-little>>, 0, "", accumulated) do
    %{
      messages: accumulated,
      remaining: remaining,
      buffer: ""
    }
  end

  #  "<<11, 0, 0, 0>>new-message"
  # def parse_frame(<<remaining::utf32-little, data::binary>>, 0, "", accumulated)
  #     when byte_size(data) == remaining do
  #   parse_frame(data, remaining, "", accumulated)
  # end

  #  "<<11, 0, 0, 0>>1st-message<<11, 0, 0, 0>>2nd-message"
  def parse_frame(<<remaining::utf32-little, data::binary>>, 0, "", accumulated) do
    parse_frame(data, remaining, "", accumulated)
  end

  def parse_frame(<<data::binary>>, read_length, buffer, accumulated)
      when byte_size(data) == read_length do
    %{
      messages: accumulated ++ [buffer <> data],
      remaining: 0,
      buffer: ""
    }
  end

  # buffer:      "previous-blah-"
  # data:        "blah<<9, 0, 0, 0>>more-blah"
  # read_length: 4
  def parse_frame(<<data::binary>>, read_length, buffer, accumulated)
      when byte_size(data) > read_length do
    {message, tail} = String.split_at(data, read_length)
    parse_frame(tail, 0, "", accumulated ++ [buffer <> message])
  end
end
