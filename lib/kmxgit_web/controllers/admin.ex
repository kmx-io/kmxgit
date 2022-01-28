defmodule KmxgitWeb.Admin do

  alias Kmxgit.IndexParams

  def page_params(index_params = %IndexParams{}, nil, nil) do
    index_params
  end
  def page_params(index_params = %IndexParams{}, page, nil) do
    %IndexParams{index_params | page: String.to_integer(page)}
  end
  def page_params(index_params = %IndexParams{}, nil, per) do
    %IndexParams{index_params | per: String.to_integer(per)}
  end
  def page_params(index_params = %IndexParams{}, page, per) do
    %IndexParams{index_params | page: String.to_integer(page),
                 per: String.to_integer(per)}
  end

  def search_param(index_params = %IndexParams{}, param) do
    %IndexParams{index_params | search: param}
  end

  def sort_param(index_params = %IndexParams{}, param) do
    if param && param != "" do
      case String.split(param, "-") do
        [col, _] -> %IndexParams{index_params | column: col, reverse: true}
        [col] -> %IndexParams{index_params | column: col}
        _ -> index_params
      end
    else
      index_params
    end
  end
end
