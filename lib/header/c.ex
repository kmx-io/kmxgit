/*
 * Copyright 2022 Thomas de Grivel <thoxdg@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
defmodule Header.C do
  def split(src) do
    split(src, "")
  end

  def split("/*" <> rest, "") do
    split(rest, "/*")
  end
  def split("/*" <> rest, acc) do
    {"", acc <> "/*" <> rest}
  end
  def split("*/\n" <> rest, acc) do
    header = acc <> "*/"
    {header, rest}
  end
  def split(<<c, rest::binary>>, acc) when is_binary(acc) do
    split(rest, acc <> <<c>>)
  end
  def split("", acc) do
    {"", acc}
  end

  def main([src_path | dest_paths]) do
    case File.read(src_path) do
      {:ok, src} ->
        {header, _} = split(src)
        Enum.each dest_paths, fn dest_path ->
          case File.read(dest_path) do
            {:ok, dest} ->
              {_, rest} = split(dest)
              result = header <> "\n" <> rest
              File.write(dest_path, result)
            {:error, e} ->
              IO.inspect("Error: #{dest_path}: #{e}")
          end
        end
      {:error, e} ->
        IO.inspect "Error: #{src_path}: #{e}"
    end
  end
end
