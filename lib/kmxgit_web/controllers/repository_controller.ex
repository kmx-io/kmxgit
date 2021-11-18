defmodule KmxgitWeb.RepositoryController do
  use KmxgitWeb, :controller

  alias Kmxgit.RepositoryManager

  def new(conn, params) do
    current_user = conn.assigns.current_user
    # TODO: check the owner part of path
    changeset = RepositoryManager.change_repository
    conn
    |> assign(:action, Routes.repository_path(conn, :create, params["owner"]))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    # TODO: handle organisations
    owner = current_user
    # TODO: check the owner part of path
    case RepositoryManager.create_repository(current_user, params["repository"]) do
      {:ok, repository} ->
        conn
        |> redirect(to: Routes.repository_path(conn, :show, owner.slug.slug, repository.slug))
      {:error, changeset} ->
        IO.inspect(changeset)
        conn
        |> assign(:action, Routes.repository_path(conn, :create, owner.slug))
        |> assign(:changeset, changeset)
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
    repo =  RepositoryManager.get_repository_by_owner_and_slug(params["owner"], slug)
    if repo do
      org = repo.organisation
      user = repo.user
      conn
      |> assign(:current_repository, repo)
      |> assign_current_organisation(org)
      |> assign(:owner, org || user)
      |> render("show.html")
    else
      not_found(conn)
    end
  end

  defp assign_current_organisation(conn, nil), do: conn
  defp assign_current_organisation(conn, org) do
    assign(conn, :current_organisation, org)
  end
  
  def edit(conn, params) do
    org =  RepositoryManager.get_repository_by_slug(params["slug"])
    changeset = RepositoryManager.change_repository(org)
    if org do
      conn
      |> assign(:action, Routes.repository_path(conn, :update, org.slug.slug))
      |> assign(:changeset, changeset)
      |> assign(:current_repository, org)
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    repository = RepositoryManager.get_repository_by_slug(params["slug"])
    if repository do
      case RepositoryManager.update_repository(repository, params["repository"]) do
        {:ok, org} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org.slug.slug))
        {:error, changeset} ->
          IO.inspect(changeset)
          conn
          |> render("edit.html", changeset: changeset,
                    action: Routes.repository_path(conn, :update, repository.slug.slug))
      end
    else
      not_found(conn)
    end
  end
end
