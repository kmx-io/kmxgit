defmodule Kmxgit.Git do
  @on_load :init

  @git_root "priv/git"

  def init do
    path = "bin/libgit_nif"
    |> String.to_charlist()
    :ok = :erlang.load_nif(path, 0)
  end

  # NIFs

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

  def create(repo) do
    dir = "#{@git_root}/#{Path.dirname(repo)}"
    name = "#{Path.basename(repo)}.git"
    :ok = File.mkdir_p(dir)
    create_nif("#{dir}/#{name}")
  end

  def create_nif(_repo) do
    exit(:nif_not_loaded)
  end

  def files(repo, tree, path, parent \\ ".") do
    dir = git_dir(repo)
    case files_nif(dir, tree, path) do
      {:ok, files} ->
        files1 = files
        |> Enum.map(fn file ->
          Map.put(file, :url, "#{parent}/#{path}/#{file.name}")
        end)
        {:ok, files1}
      x -> x
    end
  end

  def files_nif(_repo, _tree, _path) do
    exit(:nif_not_loaded)
  end

  # common functions

  def git_dir(repo) do
    if String.match?(repo, ~r/(^|\/)\.\.($|\/)/), do: raise "invalid git dir"
    "#{@git_root}/#{repo}.git"
  end
end
