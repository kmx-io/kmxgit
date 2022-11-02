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
