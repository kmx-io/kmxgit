defmodule Stack do

  def to_string(stack), do: to_string(stack, [])

  def to_string([], acc), do: acc |> Enum.reverse() |> Enum.join("\n")
  def to_string([{module, fun, arity, [file: file, line: line]} | rest], acc) do
    str = "#{module}.#{fun}/#{arity}\n    #{file}:#{line}"
    to_string(rest, [str | acc])
  end
  def to_string([{module, fun, arity, _} | rest], acc) do
    str = "#{module |> Enum.join(".")}.#{fun}/#{arity}"
    to_string(rest, [str | acc])
  end
  def to_string([{module, fun, arity, _} | rest], acc) when is_list(module) do
    str = "#{module |> Enum.join(".")}.#{fun}/#{arity}"
    to_string(rest, [str | acc])
  end
  def to_string([elt | rest], acc) do
    to_string(rest, [inspect(elt) | acc])
  end
end
