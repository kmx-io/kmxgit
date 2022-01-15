defmodule KmxgitWeb.RepositoryView do
  use KmxgitWeb, :view

  alias Kmxgit.RepositoryManager.Repository

  def tree_type({:branch, _, _}), do: gettext("Branch")
  def tree_type({:commit, _, _}), do: gettext("Commit")
  def tree_type({:tag, _, _}), do: gettext("Tag")

  def select_trees(trees), do: select_trees(trees, nil, [])
  def select_trees([{type, id, url} | rest], last_type, acc) do
    if type == last_type do
      select_trees(rest, type, [{id, url} | acc])
    else
      select_trees(rest, type, [{id, url}, {"- #{type} -", nil} | acc])
    end
  end
  def select_trees([], _, acc) do
    Enum.reverse(acc)
  end
end
