defmodule Kmxgit.Pagination do
  import Ecto.Query

  alias Kmxgit.IndexParams
  alias Kmxgit.Repo

  def query(query, %IndexParams{page: page, per: per}) do
    query
    |> limit(^per + 1)
    |> offset(^(per * (page - 1)))
  end

  def page(query, params = %IndexParams{page: page, per: per}, preload: preload) do
    result = query
    |> query(params)
    |> preload(^preload)
    |> Repo.all()
    first_page = if page > 2, do: 1
    prev_page = if page > 1, do: page - 1
    {next_page, result} = if length(result) > per do
      {page + 1, Enum.slice(result, 0..-2)}
    else
      {nil, result}
    end
    count = Repo.one(from(t in subquery(query), select: count("*")))
    count_pages = Float.ceil(count / per) |> trunc()
    last_page = if (page < count_pages - 1), do: count_pages
    first = if count > 0, do: (page - 1) * per + 1, else: 0
    last = if count > 0, do: first + length(result) - 1, else: 0
    %{count: count,
      count_pages: count_pages,
      first: first,
      first_page: first_page,
      last: last,
      last_page: last_page,
      next_page: next_page,
      page: page,
      per: per,
      prev_page: prev_page,
      result: result}
  end
end
