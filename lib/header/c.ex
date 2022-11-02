## kmxgit
## Copyright 2022 kmx.io <contact@kmx.io>
##
## Permission is hereby granted to use this software granted
## the above copyright notice and this permission paragraph
## are included in all copies and substantial portions of this
## software.
##
## THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY GUARANTEE OF
## PURPOSE AND PERFORMANCE. IN NO EVENT WHATSOEVER SHALL THE
## AUTHOR BE CONSIDERED LIABLE FOR THE USE AND PERFORMANCE OF
## THIS SOFTWARE.

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
