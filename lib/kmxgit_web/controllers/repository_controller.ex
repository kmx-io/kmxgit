defmodule KmxgitWeb.RepositoryController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.RepositoryManager
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager
  alias Kmxgit.Repo

  def new(conn, params) do
    action = Routes.repository_path(conn, :create, params["owner"])
    changeset = RepositoryManager.change_repository
    current_user = conn.assigns.current_user
    slug = SlugManager.get_slug(params["owner"])
    if !slug do
      not_found(conn)
    else
      user = slug.user
      if user do
        if user != current_user do
          not_found(conn)
        else
          conn
          |> assign(:action, action)
          |> assign(:changeset, changeset)
          |> assign(:owner, user)
          |> render("new.html")
        end
      else
        org = slug.organisation
        if org do
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
      if user do
        if user != current_user do
          not_found(conn)
        else
          create_repo(conn, user, params["repository"])
        end
      else
        org = slug.organisation
        if org do
          create_repo(conn, org, params["repository"])
        else
          not_found(conn)
        end
      end
    end
  end

  defp create_repo(conn, owner, params) do
    case Repo.transaction(fn ->
          case RepositoryManager.create_repository(owner, params) do
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

  def chunk_path(path) do
    chunk_path(path, [[]])
  end

  def chunk_path([], acc) do
    acc
    |> Enum.reverse()
    |> Enum.map(&Enum.reverse/1)
  end
  def chunk_path([first | rest], acc = [acc_first | acc_rest]) do
    if Regex.match?(~r/_/, first) do
      chunk_path(rest, [[first] | acc])
    else
      chunk_path(rest, [[first | acc_first] | acc_rest])
    end
  end

  def show(conn, params) do
    path = params["slug"] |> chunk_path()
    slug = path |> Enum.at(0) |> Enum.join("/")
    {branch, path1} = if (path1 = path |> Enum.at(1)) && (path1 |> Enum.at(0)) == "_branch" do
      {_, rest} = path |> Enum.split(2)
      rest1 = rest |> Enum.map(fn x ->
        Enum.join(x, "/")
      end)
      {_, path2} = path1 |> Enum.split(2)
      {path1 |> Enum.at(1),
       path2 ++ rest1 |> Enum.reject(&(!&1 || &1 == "")) |> Enum.join("/")}
    else
      {nil, ""}
    end
    IO.inspect([path: path, slug: slug, branch: branch, path1: path1])
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      user = repo.user
      git = %{branches: [], content: nil, files: [], status: "", valid: true}
      |> git_put_branches(repo, conn)
      |> git_put_files(repo, branch || "master", path1, conn)
      |> git_put_content(repo, branch || "master", path1)
      IO.inspect(git)
      if !branch do
        {b, _} = Enum.at(git.branches, 0)
        conn
        |> redirect(to: Routes.repository_path(conn, :show, Repository.owner_slug(repo), Repository.splat(repo) ++ ["_branch", b]))
      else
        if git.valid do
          conn
          |> assign(:branch, branch)
          |> assign(:branch_url, branch_url(git.branches, branch))
          |> assign_current_organisation(org)
          |> assign(:current_repository, repo)
          |> assign(:git, git)
          |> assign(:repo, repo)
          |> assign(:members, Repository.members(repo))
          |> assign(:owner, org || user)
          |> assign(:path, path1)
          |> render("show.html")
        else
          not_found(conn)
        end
      end
    else
      not_found(conn)
    end
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

  defp git_put_status(git = %{content: nil, valid: true}, repo) do
    case GitManager.status(Repository.full_slug(repo)) do
      {:ok, status} -> %{git | status: status}
      {:error, status} -> %{git | status: status, valid: false}
    end
  end

  defp git_put_status(git, _) do
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

  defp git_put_content(git = %{files: [%{name: name, type: _type, sha1: sha1}], valid: true}, repo, branch, path) do
    IO.inspect(git)
    case GitManager.content(Repository.full_slug(repo), branch, sha1) do
      {:ok, content} -> %{git | content: content}
      {:error, error} -> %{git | status: error}
    end
  end

  defp git_put_content(git, _, _, _) do
    git
  end

  def edit(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) || repo.user_id == current_user.id do
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
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) || repo.user_id == current_user.id do
        case RepositoryManager.update_repository(repo, params["repository"]) do
          {:ok, repo} ->
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
      end
    else
      not_found(conn)
    end
  end

  def add_user(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) || repo.user_id == current_user.id do
        conn
        |> assign(:action, Routes.repository_path(conn, :add_user_post, params["owner"], Repository.splat(repo)))
        |> assign_current_organisation(org)
        |> assign(:current_repository, repo)
        |> assign(:repo, repo)
        |> render("add_user.html")
      else
        not_found(conn)
      end
    else
      not_found(conn)
    end
  end

  def add_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["repository"]["login"]
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) || repo.user_id == current_user.id do
        case RepositoryManager.add_member(repo, login) do
          {:ok, repo} ->
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
      end
    else
      not_found(conn)
    end
  end

  def remove_user(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) || repo.user_id == current_user.id do
        conn
        |> assign(:action, Routes.repository_path(conn, :remove_user_post, params["owner"], Repository.splat(repo)))
        |> assign_current_organisation(org)
        |> assign(:current_repository, repo)
        |> assign(:repo, repo)
        |> render("remove_user.html")
      else
        not_found(conn)
      end
    else
      not_found(conn)
    end
  end

  def remove_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["repository"]["login"]
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) || repo.user_id == current_user.id do
        case RepositoryManager.remove_member(repo, login) do
          {:ok, repo} ->
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
      end
    else
      not_found(conn)
    end
  end

  def delete(conn, params) do
    current_user = conn.assigns.current_user
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) || repo.user_id == current_user.id do
        {:ok, _} = RepositoryManager.delete_repository(repo)
        conn
        |> redirect(to: Routes.slug_path(conn, :show, params["owner"]))
      else
        not_found(conn)
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
