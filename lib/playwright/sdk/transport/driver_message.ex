defmodule Playwright.SDK.Transport.DriverMessage do
  @moduledoc false
  # A "message" received from the Playwright browser server over the `Driver`
  # transport.
  #
  # Messages provide "frames" of data and may be received as:
  #
  # - A standalone frame "header", indicating what to expect in coming messages.
  # - A single complete frame, with header and "body".
  # - A full frame body, following a previously sent header.
  # - A series: multiple frames in a single message.
  # - A fragment: a partial frame which will span multiple messages.
  #
  # Message parsing is matched as follows:
  #
  # 1. `<<head::utf32-little>>` -- Message is a standalone header, indicating
  #   the `read_length` of the following frame.
  # 2. `<<head::utf32-little>><<data::binary>>` -- Message is a
  #   series of one or more frames starting with the beginning (i.e., the
  #   preceding message was complete) of a complete frame (i.e., with header
  #   and body). For example, a mult-frame series might look something like
  #   `<<11, 0, 0, 0>>1st-message<<14, 0, 0, 0>>second-message`
  # 3. `<<data::binary>>` and non-zero `read_length` equal to the length of the
  #   data -- A full, unfragmented frame body with `read_length` derived from the
  #   preceding header message.
  # 4. `<<data::binary>>` and a non-zero `read_length` *less than* the length of
  #   the data -- a series beginning with a full or partial frame body. If the
  #   frame body is a partial (fragment), it will be appended to the provided
  #   `buffer`.
  # 5. `<<data::binary>>` and a non-zero `read_length` *greater than* the length of
  #   the data -- A frame body fragment that will be continued in following
  #   messages.

  @spec parse(data :: binary(), read_length :: number(), buffer :: binary(), accumulated :: list()) :: %{
          buffer: binary(),
          frames: list(),
          remaining: number()
        }
  def parse(<<head::unsigned-little-integer-size(32)>>, 0, "", accumulated) do
    %{
      buffer: "",
      frames: accumulated,
      remaining: head
    }
  end

  def parse(<<head::unsigned-little-integer-size(32), data::binary>>, 0, "", accumulated) do
    parse(data, head, "", accumulated)
  end

  def parse(<<data::binary>>, read_length, buffer, accumulated)
      when byte_size(data) == read_length do
    %{
      buffer: "",
      frames: accumulated ++ [buffer <> data],
      remaining: 0
    }
  end

  def parse(<<data::binary>>, read_length, buffer, accumulated)
      when byte_size(data) > read_length do
    {message, tail} = bytewise_split(data, read_length)
    parse(tail, 0, "", accumulated ++ [buffer <> message])
  end

  def parse(<<data::binary>>, read_length, buffer, accumulated)
      when byte_size(data) < read_length do
    %{
      buffer: buffer <> data,
      frames: accumulated,
      remaining: read_length - byte_size(data)
    }
  end

  # private
  # ---------------------------------------------------------------------------

  # `String.split_at/2` does not account for length with unicode characters,
  # so...
  defp bytewise_split(input, offset) do
    <<head::size(offset)-binary, tail::binary>> = input
    {head, tail}
  end
end
