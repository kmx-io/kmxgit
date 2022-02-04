defmodule Errors do

  def stack_to_string(stack), do: stack_to_string(stack, [])

  def stack_to_string([], acc), do: acc |> Enum.reverse() |> Enum.join("\n")
  def stack_to_string([{module, fun, arity, [file: file, line: line]} | rest], acc) do
    str = "#{module}.#{fun}/#{arity}\n    #{file}:#{line}"
    stack_to_string(rest, [str | acc])
  end
  def stack_to_string([{module, fun, arity, _} | rest], acc) do
    str = "#{inspect(module)}.#{inspect(fun)}/#{inspect(arity)}"
    stack_to_string(rest, [str | acc])
  end
  def stack_to_string([elt | rest], acc) do
    stack_to_string(rest, [inspect(elt) | acc])
  end
end
