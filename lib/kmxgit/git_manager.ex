defmodule Kmxgit.GitManager do

  @git_root "priv/git"

  def git_dir(repo) do
    "#{@git_root}/#{repo}.git"
  end

  def status(repo) do
    dir = git_dir(repo)
    {out, status} = System.cmd("git", ["-C", dir, "status"])
    case status do
      0 -> {:ok, out}
      _ -> {:error, out}
    end
  end

  def branches(repo) do
    dir = git_dir(repo)
    {out, status} = System.cmd("git", ["branch", "-a"])
    IO.inspect {out, status}
    case status do
      0 ->
        b = out
        |> String.split("\n")
        |> filter_branches()
        |> Enum.reject(&(!&1 || &1 == ""))  
        {:ok, b}
      _ -> {:error, out}
    end
  end

  defp filter_branches(lines) do
    filter_branches(lines, [], nil)
  end

  defp filter_branches([], acc, nil) do
    Enum.reverse(acc)
  end
  defp filter_branches([], acc, main) do
    [main | Enum.reverse(acc)]
  end
  defp filter_branches([line | rest], acc, main) do
    case Regex.run(~r/^(\* )? *([^ ].*)$/, line) do
      [_, "* ", branch] -> filter_branches(rest, acc, branch)
      [_, _, branch] -> filter_branches(rest, [branch | acc], main)
      _ -> filter_branches(rest, acc, main)
    end
  end

  def content(repo, branch, path) do
    dir = git_dir(repo)
    path = if path == "" do "." else path end
    {out, status} = System.cmd("git", ["-C", dir, "cat-file", "blob", path])
    IO.inspect {out, status}
    case status do
      0 -> {:ok, out}
      _ -> {:error, out}
    end
  end

  def files(repo, tree, path, parent \\ ".") do
    dir = git_dir(repo)
    path1 = if path == "" do "." else path end
    {out, status} = System.cmd("git", ["-C", dir, "ls-tree", tree, path1])
    case status do
      0 ->
        list = out
        |> String.split("\n")
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(fn line ->
          [stat, name] = String.split(line, "\t")
          [mode, type, sha1] = String.split(stat, " ")
          url = "#{parent}/#{name}"
          %{mode: mode, name: name, sha1: sha1, type: type, url: url}
        end)
        case list do
          [%{name: ^path1, sha1: sha1, type: "tree"}] ->
            files(repo, sha1, "", "#{parent}/#{path1}")
          _ -> {:ok, list}
        end
      _ -> {:error, String.split(out, "\n")}
    end
  end

  def create(repo) do
    dir = "#{@git_root}/#{Path.dirname(repo)}"
    name = "#{Path.basename(repo)}.git"
    :ok = File.mkdir_p(dir)
    {out, status} = System.cmd("git", ["-C", dir, "init", "--bare", name])
    case status do
      0 -> {:ok, out}
      _ -> {:error, out}
    end
  end
end
