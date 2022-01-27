defmodule KmxgitWeb.Admin do

  def sort_param(param) do
    if param do
      case String.split(param, "-") do
        [col, _] -> %{column: col, reverse: true}
        [col] -> %{column: col, reverse: false}
        _ -> %{column: "id", reverse: false}
      end
    else
      %{column: "id", reverse: false}
    end
  end
end
