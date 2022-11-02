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
