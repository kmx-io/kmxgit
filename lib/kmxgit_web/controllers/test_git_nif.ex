defmodule KmxgitWeb.TestGitNifController do
  use KmxgitWeb, :controller

  alias Kmxgit.Git
  alias Kmxgit.GitManager

  def test(conn, params) do
    fun = params["fun"]
    count = String.to_integer(params["count"])
    resp = benchmark(fun, count)
    conn
    |> put_resp_content_type("text/plain")
    |> resp(200, resp)
  end

  @repo "kmx.io/kmxgit"
  @content_sha1 "7ad943b223f99c79746386c2b57d32ba6e889e2c"
  @diff_from "v0.2.0"
  @diff_to "v0.3.0"
  @tree "v0.3"
  @dir "lib/kmxgit"

  defp benchmark(fun = "branches", count) do
    out = inspect Git.branches(@repo)
    Enum.each(1..count, fn _ ->
      Git.branches(@repo)
    end)
    "#{count}x Kmxgit.Git.#{fun}(#{@repo})\n#{out}"
  end

  defp benchmark(fun = "content", count) do
    out = inspect Git.content(@repo, @content_sha1)
    Enum.each(1..count, fn _ ->
      Git.content(@repo, @content_sha1)
    end)
    "#{count}x Kmxgit.Git.#{fun}(#{@repo},#{@content_sha1})\n#{out}"
  end

  defp benchmark(fun = "create", count) do
    repo = "test_git_nif_create"
    out = Git.create(repo)
    Enum.each(1..count, fn _ ->
      GitManager.delete(repo)
      Git.create(repo)
    end)
    "#{count}x Kmxgit.Git.#{fun}(#{repo})\n#{out}"
  end

  defp benchmark(fun = "diff", count) do
    out = inspect Git.diff(@repo, @diff_from, @diff_to)
    Enum.each(1..count, fn _ ->
      Git.diff(@repo, @diff_from, @diff_to)
    end)
    "#{count}x Kmxgit.Git.#{fun}(#{@repo}, #{@diff_from}, #{@diff_to})\n#{out}"
  end

  defp benchmark(fun = "files", count) do
    out = inspect Git.files(@repo, @tree, @dir)
    Enum.each(1..count, fn _ ->
      Git.files(@repo, @tree, @dir)
    end)
    "#{count}x Kmxgit.Git.#{fun}(#{@repo}, #{@tree}, #{@dir})\n#{out}"
  end

  defp benchmark(fun = "log", count) do
    out = inspect Git.log(@repo, @tree)
    Enum.each(1..count, fn _ ->
      Git.log(@repo, @tree)
    end)
    "#{count}x Kmxgit.Git.#{fun}(#{@repo}, #{@tree})\n#{out}"
  end

  defp benchmark(fun = "tags", count) do
    out = inspect Git.tags(@repo)
    Enum.each(1..count, fn _ ->
      Git.tags(@repo)
    end)
    "#{count}x Kmxgit.Git.#{fun}(#{@repo})\n#{out}"
  end
end
