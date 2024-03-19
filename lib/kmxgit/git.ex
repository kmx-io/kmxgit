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

defmodule Kmxgit.Git do
  @on_load :init

  @git_root "priv/git"

  # common functions

  def git_dir(repo) do
    if String.match?(repo, ~r/(^|\/)\.\.($|\/)/), do: raise "invalid git dir"
    "#{@git_root}/#{repo}.git"
  end

  @disable_du true

  def du_ks(path) do
    if @disable_du do
      0
    else
      {out, status} = System.cmd("du", ["-ks", path], stderr_to_stdout: true)
      case status do
        0 ->
          {k, _} = Integer.parse(out)
          k
        x ->
          IO.inspect(x)
          0
      end
    end
  end

  def du_ks_(path) do
    if File.dir?(path) do
      case File.ls(path) do
        {:ok, files} ->
          Enum.reduce(files, 0, fn file, acc ->
            if file != "." && file != ".." do
              du_ks("#{path}/#{file}") + acc
            else
              acc
            end
          end)
        {:error, err} ->
          IO.inspect(err)
          0
      end
    else
      case File.lstat(path, time: :posix) do
        {:ok, stat} -> stat.size / 1024
        {:error, err} ->
          IO.inspect(err)
          0
      end
    end
  end

  def dir_disk_usage(dir) do
    du_ks("#{@git_root}/#{dir}")
  end

  def disk_usage(repo) do
    git_dir(repo)
    |> du_ks()
  end

  # NIFs

  def branches(repo) do
    #IO.inspect({:branches, repo})
    dir = git_dir(repo)
    #IO.inspect({:branches_nif, dir})
    branches_nif(dir)
  end

  def branches_nif(_repo) do
    exit(:nif_not_loaded)
  end

  def content(repo, sha) do
    #IO.inspect({:content, repo, sha})
    dir = git_dir(repo)
    #IO.inspect({:content_nif, dir, sha})
    content_nif(dir, sha)
  end

  def content_nif(_repo, _sha) do
    exit(:nif_not_loaded)
  end

  def create(repo) do
    #IO.inspect({:create, repo})
    dir = "#{@git_root}/#{Path.dirname(repo)}"
    name = "#{Path.basename(repo)}.git"
    :ok = File.mkdir_p(dir)
    path = "#{dir}/#{name}"
    #IO.inspect({:create_nif, path})
    create_nif(path)
  end

  def create_nif(_repo) do
    exit(:nif_not_loaded)
  end

  def diff(repo, from, to) do
    #IO.inspect({:diff, repo, from, to})
    dir = git_dir(repo)
    #IO.inspect({:diff_nif, dir, from, to})
    diff_nif(dir, from, to)
  end

  def diff_nif(_repo, _from, _to) do
    exit(:nif_not_loaded)
  end

  def files(repo, tree, path, parent \\ ".") do
    #IO.inspect({:files, repo, tree, path, parent})
    dir = git_dir(repo)
    #IO.inspect({:files_nif, dir, tree, path})
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

  def init do
    path = "#{:code.priv_dir(:kmxgit)}/libgit_nif"
    |> String.to_charlist()
    #IO.inspect({:load_nif, path, 0})
    :ok = :erlang.load_nif(path, 0)
  end

  def log(repo, tree \\ "HEAD", path \\ "", skip \\ 0, limit \\ 100) do
    #IO.inspect({:log, repo, tree, path, skip, limit})
    tree = tree || "HEAD"
    dir = git_dir(repo)
    # [%{author: author, author_email: email, hash: hash, date: date, message: msg}]
    #IO.inspect({:log_nif, dir, tree, path, skip, limit})
    log_nif(dir, tree, path, skip, limit) || []
  end

  def log_nif(_repo, _tree, _path, _skip, _limit) do
    exit(:nif_not_loaded)
  end

  def tags(repo) do
    #IO.inspect({:tags, repo})
    dir = git_dir(repo)
    #IO.inspect({:tags_nif, dir})
    tags_nif(dir)
  end

  def tags_nif(_repo) do
    exit(:nif_not_loaded)
  end
end
