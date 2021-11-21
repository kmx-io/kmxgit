defmodule KmxgitWeb.RepositoryController do
  use KmxgitWeb, :controller

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
        if user != current_user && !current_user.is_admin do
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
        if user != current_user && !current_user.is_admin do
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
            {:ok, repo} -> {:ok, repo}
            {:error, changeset} -> Repo.rollback changeset
          end
        end) do
      {:ok, repo} ->
        conn
        |> redirect(to: Routes.repository_path(conn, :show, owner.slug.slug, Repository.splat(repo)))
      {:error, changeset} ->
        IO.inspect(changeset)
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
    slug = Enum.join(params["slug"], "/")
    repo = RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      conn
      |> assign_current_organisation(org)
      |> assign(:current_repository, repo)
      |> assign(:repo, repo)
      |> assign(:members, Repository.members(repo))
      |> render("show.html")
    else
      not_found(conn)
    end
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
            IO.inspect(changeset)
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
