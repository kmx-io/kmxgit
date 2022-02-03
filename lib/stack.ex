defmodule Stack do

  def to_string(stack), do: to_string(stack, [])

  def to_string([], acc), do: acc |> Enum.reverse() |> Enum.join("\n")
  def to_string([elt | rest], acc), do: to_string(rest, [inspect(elt) | acc])
end
