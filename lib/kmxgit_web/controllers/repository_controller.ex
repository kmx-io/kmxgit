defmodule KmxgitWeb.RepositoryController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.RepositoryManager
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager
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
        if org && org.users |> Enum.find(& &1.id == current_user.id) do
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
                  |> Repository.changeset(%{})
                  |> Ecto.Changeset.add_error(:git, e)
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
        |> assign(:action, Routes.repository_path(conn, :create, owner.slug.slug))
        |> assign(:changeset, changeset)
        |> assign(:owner, owner)
        |> render("new.html")
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def show(conn, params) do
    current_user = conn.assigns.current_user
    chunks = params["slug"] |> chunk_path()
    slug = chunks |> Enum.at(0) |> Enum.join("/")
    {branch, path} = get_branch_and_path(chunks)
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo && Enum.find(Repository.members(repo), fn u -> u.id == current_user.id end) do
      org = repo.organisation
      user = repo.user
      git = setup_git(repo, branch || "master", path, conn)
      first_branch = Enum.at(git.branches, 0)
      if !branch && first_branch do
        {b, _} = first_branch
        conn
        |> redirect(to: Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo) ++ ["_branch", b]))
      else
        if git.valid do
          conn
          |> assign(:branch, branch)
          |> assign(:branch_url, if git.branches != [] do branch_url(git.branches, branch) end)
          |> assign_current_organisation(org)
          |> assign(:current_repository, repo)
          |> assign(:git, git)
          |> assign(:repo, repo)
          |> assign(:members, Repository.members(repo))
          |> assign(:owner, org || user)
          |> assign(:path, path)
          |> render("show.html")
        else
          not_found(conn)
        end
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

  defp get_branch_and_path(chunks) do
    if (path = chunks |> Enum.at(1)) && (path |> Enum.at(0)) == "_branch" do
      {_, rest} = chunks |> Enum.split(2)
      rest1 = rest |> Enum.map(fn x ->
        Enum.join(x, "/")
      end)
      {["_branch", branch], path1} = path |> Enum.split(2)
      {branch,
       path1 ++ rest1 |> Enum.reject(&(!&1 || &1 == "")) |> Enum.join("/")}
    else
      {nil, ""}
    end
  end

  defp setup_git(repo, branch, path, conn) do
    %{branches: [],
      content: nil,
      files: [],
      readme: [],
      status: "",
      valid: true}
    |> git_put_branches(repo, conn)
    |> git_put_files(repo, branch, path, conn)
    |> git_put_content(repo)
    |> git_put_readme(repo)
  end

  defp branch_url([{b, url} | rest], branch) do
    if b == branch do
      url
    else
      branch_url(rest, branch)
    end
  end

  defp git_put_branches(git = %{valid: true}, repo, conn) do
    case GitManager.branches(Repository.full_slug(repo)) do
      {:ok, branches} ->
        branches = branches
        |> Enum.map(fn b ->
          url = Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo) ++ ["_branch", b])
          {b, url}
        end)
        %{git | branches: branches}
      {:error, status} -> %{git | status: status, valid: false}
    end
  end
  defp git_put_branches(git, _, _) do
    git
  end

  defp git_put_files(git = %{valid: true}, repo, branch, subdir, conn) do
    case GitManager.files(Repository.full_slug(repo), branch, subdir) do
      {:ok, []} -> git
      {:ok, files} ->
        files = files
        |> Enum.map(fn f = %{url: url} ->
          %{f | url: Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo) ++ ["_branch", branch | String.split(url, "/")])}
        end)
        %{git | files: files}
      {:error, status} -> %{git | status: "#{git.status}\n#{status}", valid: false}
    end
  end
  defp git_put_files(git, _, _, _, _) do
    git
  end

  defp git_put_content(git = %{files: [%{type: "blob", sha1: sha1}], valid: true}, repo) do
    case GitManager.content(Repository.full_slug(repo), sha1) do
      {:ok, content} -> %{git | content: content}
      {:error, error} -> %{git | status: error}
    end
  end

  defp git_put_content(git, _) do
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
      org = repo.organisation
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
        {:ok, repo} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.repository_path(conn, :show, params["owner"], Repository.splat(repo)))
        {:error, changeset} ->
          conn
          |> assign(:action, Routes.repository_path(conn, :update, params["owner"], Repository.splat(repo)))
          |> assign(:changeset, changeset)
          |> assign_current_organisation(org)
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
  defp assign_current_organisation(conn, %Ecto.Association.NotLoaded{}), do: conn
  defp assign_current_organisation(conn, org) do
    assign(conn, :current_organisation, org)
  end
  
end
