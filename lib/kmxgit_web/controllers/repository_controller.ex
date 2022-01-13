defmodule KmxgitWeb.RepositoryController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager
  alias Kmxgit.UserManager.User
  alias Kmxgit.Repo

  def new(conn, params) do
    action = Routes.repository_path(conn, :create, params["owner"])
    current_user = conn.assigns.current_user
    slug = SlugManager.get_slug(params["owner"])
    if !slug do
      not_found(conn)
    else
      if slug.user && slug.user.id == current_user.id do
        changeset = RepositoryManager.change_repository(slug.user)
        conn
        |> assign(:action, action)
        |> assign(:changeset, changeset)
        |> assign(:owner, slug.user)
        |> render("new.html")
      else
        org = slug.organisation
        if org && Organisation.owner?(org, current_user) do
          changeset = RepositoryManager.change_repository(org)
          conn
          |> assign(:action, action)
          |> assign(:changeset, changeset)
          |> assign(:current_organisation, org)
          |> assign(:owner, org)
          |> render("new.html")
        else
          not_found(conn)
        end
      end
    end
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    slug = SlugManager.get_slug(params["owner"])
    if !slug do
      not_found(conn)
    else
      user = slug.user
      if user && user.id == current_user.id do
        create_repo(conn, params["repository"], user)
      else
        org = slug.organisation
        if org && Organisation.owner?(org, current_user) do
          create_repo(conn, params["repository"], org)
        else
          not_found(conn)
        end
      end
    end
  end

  defp create_repo(conn, params, owner) do
    case Repo.transaction(fn ->
          case RepositoryManager.create_repository(params, owner) do
            {:ok, repo} ->
              case GitManager.create(Repository.full_slug(repo)) do
                {:ok, _} -> repo
                {:error, e} ->
                  repo
                  |> Repository.changeset(params)
                  |> Ecto.Changeset.add_error(:git, e)
                  |> Repo.rollback
              end
            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end) do
      {:ok, repo} ->
        case GitManager.update_auth() do
          :ok -> :ok = GitManager.public_access(Repository.full_slug(repo), repo.public_access)
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.repository_path(conn, :show, owner.slug.slug, Repository.splat(repo)))
      {:error, changeset} ->
        IO.inspect changeset
        conn
        |> assign(:action, Routes.repository_path(conn, :create, owner.slug.slug))
        |> assign(:changeset, changeset)
        |> assign_current_organisation(owner)
        |> assign(:owner, owner)
        |> render("new.html")
    end
  end

  def show(conn, params) do
    current_user = conn.assigns[:current_user]
    chunks = params["slug"] |> chunk_path()
    slug = chunks |> Enum.at(0) |> Enum.join("/")
    {op, branch, path} = get_op_branch_and_path(chunks)
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && repo.public_access || Repository.member?(repo, current_user) do
      org = repo.organisation
      user = repo.user
      git = setup_git(repo, branch || "master", path, conn, op)
      first_branch = case Enum.at(git.branches, 0) do
                       {first_branch, _} -> first_branch
                       nil -> nil
                     end
      branch1 = branch || first_branch
      if git.valid do
        show_op(conn, op || :tree, branch1, git, org, path, repo, user)
      else
        IO.inspect(:invalid_git)
        not_found(conn)
      end
    else
      not_found(conn)
    end
  end

  def chunk_path(path) do
    chunk_path(path, [[]])
  end

  def chunk_path([], acc) do
    acc
    |> Enum.reverse()
    |> Enum.map(&Enum.reverse/1)
  end
  def chunk_path([first | rest], acc = [acc_first | acc_rest]) do
    if Regex.match?(~r/^_/, first) do
      chunk_path(rest, [[first] | acc])
    else
      chunk_path(rest, [[first | acc_first] | acc_rest])
    end
  end

  defp get_op_branch_and_path(chunks) do
    if path = chunks |> Enum.at(1) do
      op = case path |> Enum.at(0) do
             "_blob" -> :blob
             "_commit" -> :commit
             "_log" -> :log
             "_tag" -> :tag
             "_tree" -> :tree
             x ->
               IO.puts "Unknown operation #{x}"
               :unknown
           end
      if op do
        {_, rest} = chunks |> Enum.split(2)
        rest1 = rest |> Enum.map(fn x ->
          Enum.join(x, "/")
        end)
        {[_, branch], path1} = path |> Enum.split(2)
        path2 = (path1 ++ rest1)
        |> Enum.reject(&(!&1 || &1 == ""))
        |> Enum.join("/")
        path3 = if path2 != "", do: path2
        {op, branch, path3}
      else
        {nil, nil, nil}
      end
    else
      {nil, nil, nil}
    end
  end

  defp setup_git(repo, branch, path, conn, op) do
    %{branches: [],
      content: nil,
      content_html: nil,
      content_type: nil,
      filename: nil,
      files: [],
      log1: nil,
      readme: [],
      status: "",
      tags: [],
      valid: true}
    |> git_put_branches(repo, conn, op, path)
    |> git_put_files(repo, branch, path, conn)
    |> git_put_content(repo, path)
    |> git_put_readme(repo)
    |> git_put_log1(repo, branch, path)
    |> git_put_tags(repo)
  end

  defp git_put_branches(git = %{valid: true}, repo, conn, op, path) do
    case GitManager.branches(Repository.full_slug(repo)) do
      {:ok, branches} ->
        branches = branches
        |> Enum.map(fn branch ->
          url = Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo) ++ ["_#{op || :tree}", branch] ++ (if path, do: String.split(path, "/"), else: []))
          {branch, url}
        end)
        %{git | branches: branches}
      {:error, status} -> %{git | status: status, valid: false}
    end
  end
  defp git_put_branches(git, _, _, _, _) do
    git
  end

  defp git_put_files(git = %{valid: true}, repo, branch, subdir, conn) do
    case GitManager.files(Repository.full_slug(repo), branch, subdir || "") do
      {:ok, []} -> git
      {:ok, files} ->
        files = files
        |> Enum.map(fn f = %{url: url} ->
          %{f | url: Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo) ++ ["_tree", branch | String.split(url, "/")])}
        end)
        %{git | files: files}
      {:error, status} -> %{git | status: "#{git.status}\n#{status}", valid: false}
    end
  end
  defp git_put_files(git, _, _, _, _) do
    git
  end

  defp mime_type(content, ext \\ nil) do
    if String.valid?(content) do
      "text/plain"
    else
      MIME.type(ext)
    end
  end

  defp filename(path) do
    path
    |> String.split("/")
    |> List.last()
  end

  defp git_put_content(git = %{files: [%{name: name, sha1: sha1, type: "blob"}], valid: true}, repo, path) do
    if (path == name) do
      case GitManager.content(Repository.full_slug(repo), sha1) do
        {:ok, content} ->
          type = case Regex.run(~r/[.]([^.]+)$/, path) do
                   [_, ext] -> mime_type(content, ext)
                   _ -> mime_type(content)
                 end
          content_html = Pygmentize.html(content, filename(name))
          IO.inspect(path: path, name: name, type: type)
          %{git | content: content, content_html: content_html, content_type: type, filename: name}
        {:error, error} -> %{git | status: error}
      end
    else
      git
    end
  end

  defp git_put_content(git, _, _) do
    git
  end

  defp git_put_readme(git = %{files: files, valid: true}, repo) do
    readme = Enum.map(files, fn f ->
      if String.match?(f.name, ~r/^readme\.md$/i) do
        {:ok, content} = GitManager.content(Repository.full_slug(repo), f.sha1)
        %{html: Earmark.as_html!(content),
          name: f.name,
          txt: content}
      else
        if String.match?(f.name, ~r/^readme(.txt)?$/i) do
          {:ok, content} = GitManager.content(Repository.full_slug(repo), f.sha1)
          %{html: nil,
            name: f.name,
            txt: content}
        end
      end
    end)
    |> Enum.filter(& &1)
    %{git | readme: readme}
  end
  defp git_put_readme(git, _) do
    git
  end

  defp git_put_log1(git, repo, branch, path) do
    slug = Repository.full_slug(repo)
    log1 = case if path, do: GitManager.log1_file(slug, path, branch), else: GitManager.log1(slug, branch) do
             {:ok, log1} -> log1
             {:error, err} ->
               IO.inspect(err)
               nil
           end
    %{git | log1: log1}
  end

  defp git_put_tags(git, repo) do
    {:ok, tags} = GitManager.tags(Repository.full_slug(repo))
    %{git | tags: tags}
  end

  defp git_log(repo, branch, path) do
    slug = Repository.full_slug(repo)
    {:ok, log} = if path do
      GitManager.log_file(slug, path, branch)
    else
      GitManager.log(slug, branch)
    end
    log
  end

  defp show_op(conn, :blob, _branch, git, _org, _path, _repo, _user) do
    if (git.content) do
      conn
      |> put_resp_content_type("application/octet-stream")
      |> put_resp_header("Content-Disposition", "attachment; filename=#{git.filename |> URI.encode()}")
      |> resp(200, git.content)
    else
      not_found(conn)
    end
  end
  defp show_op(conn, :commit, _branch, git, org, _path, repo, _user) do
    IO.inspect(git)
    {:ok, diff} = GitManager.diff(Repository.full_slug(repo), git.log1.hash, "#{git.log1.hash}~1")
    diff_html = Pygmentize.html(diff, "diff.patch")
    conn
    |> assign(:commit, git.log1)
    |> assign_current_organisation(org)
    |> assign(:current_repository, repo)
    |> assign(:diff_html, diff_html)
    |> assign(:repo, repo)
    |> render("commit.html")
  end
  defp show_op(conn, :log, branch, git, org, path, repo, _user) do
    log = git_log(repo, branch, path)
    conn
    |> assign(:branch, branch)
    |> assign(:branch_url, Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo, ["_log", branch] ++ (if path, do: String.split(path, "/"), else: []))))
    |> assign_current_organisation(org)
    |> assign(:current_repository, repo)
    |> assign(:git, git)
    |> assign(:log, log)
    |> assign(:path, path)
    |> assign(:repo, repo)
    |> render("log.html")
  end
  defp show_op(conn, :tag, branch, git, org, _path, repo, _user) do
    tag = Enum.find(git.tags, fn tag -> tag.tag == branch end)
    conn
    |> assign_current_organisation(org)
    |> assign(:current_repository, repo)
    |> assign(:repo, repo)
    |> assign(:tag, tag)
    |> render("tag.html")
  end
  defp show_op(conn, :tree, branch, git, org, path, repo, user) do
    conn
    |> assign(:branch, branch)
    |> assign(:branch_url, branch && Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo, ["_tree", branch] ++ (if path, do: String.split(path, "/"), else: []))))
    |> assign_current_organisation(org)
    |> assign(:current_repository, repo)
    |> assign(:git, git)
    |> assign(:repo, repo)
    |> assign(:members, Repository.members(repo))
    |> assign(:owner, org || user)
    |> assign(:path, path)
    |> render("show.html")
  end
  defp show_op(conn, _op, _branch, _git, _org, _path, _repo, _user) do
    not_found(conn)
  end

  def edit(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.owner?(repo, current_user) do
      org = repo.organisation
      changeset = RepositoryManager.change_repository(repo)
      conn
      |> assign(:action, Routes.repository_path(conn, :update, params["owner"], Repository.splat(repo)))
      |> assign(:changeset, changeset)
      |> assign_current_organisation(org)
      |> assign(:current_repository, repo)
      |> assign(:repo, repo)
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.owner?(repo, current_user) do
      case Repo.transaction(fn ->
            case RepositoryManager.update_repository(repo, params["repository"]) do
              {:ok, repo1} ->
                s = Repository.full_slug(repo)
                s1 = Repository.full_slug(repo1)
                if s != s1 do
                  case GitManager.rename(s, s1) do
                    :ok -> repo1
                    {:error, err} -> Repo.rollback(err)
                  end
                else
                  repo1
                end
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end) do
        {:ok, repo1} ->
          case GitManager.update_auth() do
            :ok -> :ok = GitManager.public_access(Repository.full_slug(repo1), repo1.public_access)
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.repository_path(conn, :show, Repository.owner_slug(repo1), Repository.splat(repo1)))
        {:error, changeset} ->
          conn
          |> assign(:action, Routes.repository_path(conn, :update, params["owner"], Repository.splat(repo)))
          |> assign(:changeset, changeset)
          |> assign_current_organisation(repo.organisation)
          |> assign(:current_repository, repo)
          |> assign(:repo, repo)
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end

  def add_user(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.owner?(repo, current_user) do
      org = repo.organisation
      conn
      |> assign(:action, Routes.repository_path(conn, :add_user_post, params["owner"], Repository.splat(repo)))
      |> assign_current_organisation(org)
      |> assign(:current_repository, repo)
      |> assign(:repo, repo)
      |> render("add_user.html")
    else
      not_found(conn)
    end
  end

  def add_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["repository"]["login"]
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.owner?(repo, current_user) do
      org = repo.organisation
      case RepositoryManager.add_member(repo, login) do
        {:ok, repo} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.repository_path(conn, :show, params["owner"], Repository.splat(repo)))
        {:error, _} ->
          conn
          |> assign(:action, Routes.repository_path(conn, :add_user_post, params["owner"], Repository.splat(repo)))
          |> assign_current_organisation(org)
          |> assign(:current_repository, repo)
          |> assign(:repo, repo)
          |> render("add_user.html")
      end
    else
      not_found(conn)
    end
  end

  def remove_user(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.owner?(repo, current_user) do
      org = repo.organisation
      conn
      |> assign(:action, Routes.repository_path(conn, :remove_user_post, params["owner"], Repository.splat(repo)))
      |> assign_current_organisation(org)
      |> assign(:current_repository, repo)
      |> assign(:repo, repo)
      |> render("remove_user.html")
    else
      not_found(conn)
    end
  end

  def remove_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["repository"]["login"]
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.owner?(repo, current_user) do
      org = repo.organisation
      case RepositoryManager.remove_member(repo, login) do
        {:ok, repo} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.repository_path(conn, :show, params["owner"], Repository.splat(repo)))
        {:error, _} ->
          conn
          |> assign(:action, Routes.repository_path(conn, :remove_user_post, params["owner"], Repository.splat(repo)))
          |> assign_current_organisation(org)
          |> assign(:current_repository, repo)
          |> assign(:repo, repo)
          |> render("remove_user.html")
      end
    else
      not_found(conn)
    end
  end

  def delete(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.owner?(repo, current_user) do
      case Repo.transaction(fn ->
            case RepositoryManager.delete_repository(repo) do
              {:ok, _} -> :ok = GitManager.delete(Repository.full_slug(repo))
              {:error, changeset} -> Repo.rollback changeset
            end
          end) do
        {:ok, _} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.slug_path(conn, :show, params["owner"]))
        {:error, _changeset} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :edit, params["owner"]))
      end
    else
      not_found(conn)
    end
  end

  defp assign_current_organisation(conn, nil), do: conn
  defp assign_current_organisation(conn, %User{}), do: conn
  defp assign_current_organisation(conn, org = %Organisation{}) do
    assign(conn, :current_organisation, org)
  end

  def fork(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.member?(repo, current_user) do
      org = repo.organisation
      changeset = RepositoryManager.change_repository(repo)
      conn
      |> assign(:action, Routes.repository_path(conn, :fork_post, params["owner"], Repository.splat(repo)))
      |> assign(:changeset, changeset)
      |> assign_current_organisation(org)
      |> assign(:current_repository, repo)
      |> assign(:repo, repo)
      |> render("fork.html")
    else
      not_found(conn)
    end
  end

  def fork_post(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Repository.member?(repo, current_user) do
      fork_to = params["repository"]["fork_to"]
      slug = String.split(fork_to, "/") |> Enum.at(0) |> SlugManager.get_slug()
      if slug do
        user = slug.user
        if user do
          if user.id == current_user.id do
            fork_repo(conn, params["repository"], user, repo)
          else
            changeset = repo
            |> Repository.changeset(params["repository"])
            |> Ecto.Changeset.add_error(:fork_to, "you cannot fork to another user")
            |> changeset_put_action(:fork)
            conn
            |> assign(:action, Routes.repository_path(conn, :fork_post, Repository.owner_slug(repo), Repository.splat(repo)))
            |> assign(:changeset, changeset)
            |> assign_current_organisation(repo.organisation)
            |> assign(:current_repository, repo)
            |> assign(:repo, repo)
            |> render("fork.html")
          end
        else
          %Organisation{} = org = slug.organisation
          if Organisation.owner?(org, current_user) do
            fork_repo(conn, params["repository"], org, repo)
          else
            changeset = repo
            |> Repository.changeset(params["repository"])
            |> Ecto.Changeset.add_error(:fork_to, "you don't have the permission to fork to this organisation")
            |> changeset_put_action(:fork)
            conn
            |> assign(:action, Routes.repository_path(conn, :fork_post, Repository.owner_slug(repo), Repository.splat(repo)))
            |> assign(:changeset, changeset)
            |> assign_current_organisation(repo.organisation)
            |> assign(:current_repository, repo)
            |> assign(:repo, repo)
            |> render("fork.html")
          end
        end
      else
        changeset = repo
        |> Repository.changeset(params["repository"])
        |> Ecto.Changeset.add_error(:fork_to, "owner was not found")
        |> changeset_put_action(:fork)
        conn
        |> assign(:action, Routes.repository_path(conn, :fork_post, Repository.owner_slug(repo), Repository.splat(repo)))
        |> assign(:changeset, changeset)
        |> assign_current_organisation(repo.organisation)
        |> assign(:current_repository, repo)
        |> assign(:repo, repo)
        |> render("fork.html")
      end
    else
      not_found(conn)
    end
  end

  defp fork_repo(conn, params, owner, origin) do
    [_ | slug] = String.split(params["fork_to"], "/")
    slug = Enum.join(slug, "/")
    case Repo.transaction(fn ->
          case RepositoryManager.fork_repository(origin, owner, slug) do
            {:ok, repo} ->
              case GitManager.fork(Repository.full_slug(origin), Repository.full_slug(repo)) do
                :ok -> repo
                {:error, e} ->
                  repo
                  |> Repository.changeset(params)
                  |> Ecto.Changeset.add_error(:fork_to, e)
                  |> changeset_put_action(:fork)
                  |> Repo.rollback
              end
            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end) do
      {:ok, repo} ->
        case GitManager.update_auth() do
          :ok -> nil
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.repository_path(conn, :show, owner.slug.slug, Repository.splat(repo)))
      {:error, changeset} ->
        IO.inspect changeset
        conn
        |> assign(:action, Routes.repository_path(conn, :fork_post, Repository.owner_slug(origin), Repository.splat(origin)))
        |> assign(:changeset, changeset)
        |> assign_current_organisation(origin.organisation)
        |> assign(:current_repository, origin)
        |> assign(:repo, origin)
        |> render("fork.html")
    end
  end

  defp changeset_put_action(changeset, action) do
    %Ecto.Changeset{changeset | action: action}
  end
end
