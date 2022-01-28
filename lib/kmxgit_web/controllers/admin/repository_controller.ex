defmodule KmxgitWeb.Admin.RepositoryController do
  use KmxgitWeb, :controller

  alias Kmxgit.IndexParams
  alias Kmxgit.GitManager
  alias Kmxgit.RepositoryManager
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager
  alias KmxgitWeb.ErrorView

  def index(conn, params) do
    index_params = %IndexParams{}
    |> KmxgitWeb.Admin.sort_param(params["sort"])
    |> KmxgitWeb.Admin.search_param(params["search"])
    repos = RepositoryManager.list_repositories(index_params)
    conn
    |> assign(:repos, repos)
    |> assign(:index, index_params)
    |> render("index.html")
  end

  def new(conn, _params) do
    changeset = RepositoryManager.change_repository
    conn
    |> assign(:action, Routes.admin_repository_path(conn, :create))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    slug = SlugManager.get_slug(params["owner"])
    if slug do
      user = slug.user
      if user do
        if user == current_user do
          create_repo(conn, user, params["repository"])
        else
          not_found(conn)
        end
      else
        org = slug.organisation
        if org do
          create_repo(conn, org, params["repository"])
        else
          not_found(conn)
        end
      end
    else
      not_found(conn)
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
                  |> Repository.changeset(params)
                  |> Ecto.Changeset.add_error(:git, e)
                  |> Repo.rollback
              end
            {:error, changeset} -> Repo.rollback changeset
          end
        end) do
      {:ok, repo} ->
        case GitManager.update_auth() do
          :ok -> :ok = GitManager.public_access(Repository.full_slug(repo), repo.public_access)
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.admin_repository_path(conn, :show, repo))
      {:error, changeset} ->
        conn
        |> assign(:action, Routes.admin_repository_path(conn, :create))
        |> assign(:changeset, changeset)
        |> assign(:owner, owner)
        |> render("new.html")
    end
  end

  def show(conn, params) do
    repo = RepositoryManager.get_repository!(params["id"])
    |> RepositoryManager.put_disk_usage()
    conn
    |> assign(:members, Repository.members(repo))
    |> assign(:repo, repo)
    |> render("show.html")
  end

  def edit(conn, params) do
    repo = RepositoryManager.get_repository!(params["id"])
    changeset = RepositoryManager.change_repository(repo)
    conn
    |> assign(:action, Routes.admin_repository_path(conn, :update, repo))
    |> assign(:changeset, changeset)
    |> assign(:repo, repo)
    |> render("edit.html")
  end

  def update(conn, params) do
    repo = RepositoryManager.get_repository!(params["id"])
    case Repo.transaction(fn ->
          case RepositoryManager.update_repository(repo, params["repository"]) do
            {:ok, repo1} ->
              s = Repository.full_slug(repo)
              s1 = Repository.full_slug(repo1)
              if s != s1 do
                GitManager.rename(s, s1)
              end
              repo1
            {:error, changeset} -> Repo.rollback changeset
          end
        end) do
      {:ok, repo1} ->
        case GitManager.update_auth() do
          :ok -> :ok = GitManager.public_access(Repository.full_slug(repo1), repo1.public_access)
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.admin_repository_path(conn, :show, repo1))
      {:error, changeset} ->
        conn
        |> assign(:action, Routes.admin_repository_path(conn, :update, repo))
        |> assign(:changeset, changeset)
        |> assign(:repo, repo)
        |> render("edit.html")
    end
  end

  def add_user(conn, params) do
    repo = RepositoryManager.get_repository!(params["repository_id"])
    conn
    |> assign(:action, Routes.admin_repository__path(conn, :add_user_post, repo))
    |> assign(:repo, repo)
    |> render("add_user.html")
  end

  def add_user_post(conn, params) do
    login = params["repository"]["login"]
    repo = RepositoryManager.get_repository!(params["repository_id"])
    case RepositoryManager.add_member(repo, login) do
      {:ok, repo} ->
        case GitManager.update_auth() do
          :ok -> nil
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.admin_repository_path(conn, :show, repo))
      {:error, _} ->
        conn
        |> assign(:action, Routes.admin_repository__path(conn, :add_user_post, repo))
        |> assign(:repo, repo)
        |> render("add_user.html")
    end
  end

  def remove_user(conn, params) do
    repo = RepositoryManager.get_repository!(params["repository_id"])
    conn
    |> assign(:action, Routes.admin_repository__path(conn, :remove_user_post, repo))
    |> assign(:repo, repo)
    |> render("remove_user.html")
  end

  def remove_user_post(conn, params) do
    login = params["repository"]["login"]
    repo = RepositoryManager.get_repository!(params["repository_id"])
    case RepositoryManager.remove_member(repo, login) do
      {:ok, repo} ->
        case GitManager.update_auth() do
          :ok -> nil
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.admin_repository_path(conn, :show, repo))
      {:error, _} ->
        conn
        |> assign(:action, Routes.admin_repository__path(conn, :remove_user_post, repo))
        |> assign(:repo, repo)
        |> render("remove_user.html")
    end
  end

  def delete(conn, params) do
    repo = RepositoryManager.get_repository(params["id"])
    if repo do
      case Repo.transaction(fn ->
            case RepositoryManager.delete_repository(repo) do
              {:ok, _} -> GitManager.delete(Repository.full_slug(repo))
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end) do
        {:ok, _} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.admin_repository_path(conn, :index))
        {:error, changeset} ->
          conn
          |> assign(:action, Routes.admin_repository_path(conn, :update, repo))
          |> assign(:changeset, changeset)
          |> assign(:repo, repo)
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end
end
