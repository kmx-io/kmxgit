defmodule Kmxgit.Git do
  @on_load :init

  @git_root "priv/git"

  def init do
    path = "bin/libgit_nif"
    |> String.to_charlist()
    :ok = :erlang.load_nif(path, 0)
  end

  # Functions

  def branches(repo) do
    repo
    |> git_dir()
    |> branches_nif()
  end

  def branches_nif(_repo) do
    exit(:nif_not_loaded)
  end

  def content(repo, sha) do
    repo
    |> git_dir()
    |> content_nif(sha)
  end

  def content_nif(_repo, _sha) do
    exit(:nif_not_loaded)
  end

  # common functions

  def git_dir(repo) do
    if String.match?(repo, ~r/(^|\/)\.\.($|\/)/), do: raise "invalid git dir"
    "#{@git_root}/#{repo}.git"
  end
end
