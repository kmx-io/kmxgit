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
