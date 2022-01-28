defmodule KmxgitWeb.Admin do

  alias Kmxgit.IndexParams

  def sort_param(index_params = %IndexParams{}, param) do
    if param do
      case String.split(param, "-") do
        [col, _] -> %IndexParams{index_params | column: col, reverse: true}
        [col] -> %IndexParams{index_params | column: col}
        _ -> index_params
      end
    else
      index_params
    end
  end

  def search_param(index_params = %IndexParams{}, param) do
    %IndexParams{index_params | search: param}
  end
end
