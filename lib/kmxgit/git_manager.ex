defmodule Kmxgit.GitManager do

  @git_root "priv/git"

  def git_dir(repo) do
    "#{@git_root}/#{repo}.git"
  end

  def status(repo) do
    dir = git_dir(repo)
    {out, status} = System.cmd("git", ["-C", dir, "status"], stderr_to_stdout: true)
    case status do
      0 -> {:ok, out}
      _ -> {:error, out}
    end
  end

  def branches(repo) do
    dir = git_dir(repo)
    {out, status} = System.cmd("git", ["branch", "--list"], stderr_to_stdout: true)
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
    {out, status} = System.cmd("git", ["-C", dir, "cat-file", "blob", path], stderr_to_stdout: true)
    case status do
      0 -> {:ok, out}
      _ -> {:error, out}
    end
  end

  def files(repo, tree, path, parent \\ ".") do
    dir = git_dir(repo)
    path1 = if path == "" do "." else path end
    {out, status} = System.cmd("git", ["-C", dir, "ls-tree", tree, path1], stderr_to_stdout: true)
    IO.inspect {out, status}
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
      _ ->
        if Regex.match?(~r(^fatal: Not a valid object name ), out) do
          {:ok, []}
        else
          {:error, String.split(out, "\n")}
        end
    end
  end

  def rename(from, to) do
    dir_from = git_dir(from)
    dir_to = git_dir(to)
    dir = Path.dirname(dir_to)
    :ok = File.mkdir_p(dir)
    {out, status} = System.cmd("mv", [dir_from, dir_to], stderr_to_stdout: true)
    case status do
      0 -> {:ok, out}
      _ -> {:error, out}
    end
  end

  def create(repo) do
    dir = "#{@git_root}/#{Path.dirname(repo)}"
    name = "#{Path.basename(repo)}.git"
    :ok = File.mkdir_p(dir)
    {out, status} = System.cmd("git", ["-C", dir, "init", "--bare", name], stderr_to_stdout: true)
    case status do
      0 -> {:ok, out}
      _ -> {:error, out}
    end
  end

  def delete(repo) do
    dir = git_dir(repo)
    case System.cmd("rm", ["-rf", dir], stderr_to_stdout: true) do
      {"", 0} -> :ok
      {err, _} -> {:error, err}
    end
  end
end
