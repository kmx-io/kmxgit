defmodule KmxgitWeb.OrganisationController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.OrganisationManager
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo

  def new(conn, _params) do
    _ = conn.assigns.current_user
    changeset = OrganisationManager.change_organisation
    conn
    |> assign(:action, Routes.organisation_path(conn, :create))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    case OrganisationManager.create_organisation(current_user, params["organisation"]) do
      {:ok, organisation} ->
        conn
        |> redirect(to: Routes.slug_path(conn, :show, organisation.slug.slug))
      {:error, changeset} ->
        conn
        |> assign(:action, Routes.organisation_path(conn, :create))
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

  def edit(conn, params) do
    current_user = conn.assigns.current_user
    org =  OrganisationManager.get_organisation_by_slug(params["slug"])
    changeset = OrganisationManager.change_organisation(org)
    if org && Organisation.owner?(org, current_user) do
      conn
      |> assign(:action, Routes.organisation_path(conn, :update, org.slug.slug))
      |> assign(:changeset, changeset)
      |> assign(:current_organisation, org)
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case Repo.transaction(fn ->
            case OrganisationManager.update_organisation(org, params["organisation"]) do
              {:ok, org1} ->
                if org.slug.slug != org1.slug.slug do
                  case GitManager.rename_dir(org.slug.slug, org1.slug.slug) do
                    :ok ->
                      case GitManager.update_auth() do
                        :ok -> nil
                        error -> IO.inspect(error)
                      end
                      org1
                    {:error, err} -> Repo.rollback(err)
                  end
                else
                  org1
                end
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end) do
        {:ok, org1} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org1.slug.slug))
        {:error, changeset} ->
          conn
          |> assign(:action, Routes.organisation_path(conn, :update, org.slug.slug))
          |> assign(:changeset, changeset)
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end

  def add_user(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      conn
      |> assign(:action, Routes.organisation_path(conn, :add_user_post, params["slug"]))
      |> assign(:current_organisation, org)
      |> render("add_user.html")
    else
      not_found(conn)
    end
  end

  def add_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["organisation"]["login"]
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case OrganisationManager.add_user(org, login) do
        {:ok, org} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org.slug.slug))
        {:error, _e} ->
          conn
          |> assign(:action, Routes.organisation_path(conn, :add_user_post, params["slug"]))
          |> assign(:current_organisation, org)
          |> render("add_user.html")
      end
    else
      not_found(conn)
    end
  end

  def remove_user(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      conn
      |> assign(:action, Routes.organisation_path(conn, :remove_user_post, params["slug"]))
      |> assign(:current_organisation, org)
      |> render("remove_user.html")
    else
      not_found(conn)
    end
  end

  def remove_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["organisation"]["login"]
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case OrganisationManager.remove_user(org, login) do
        {:ok, org} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org.slug.slug))
        {:error, _} ->
          conn
          |> assign(:action, Routes.organisation_path(conn, :remove_user_post, params["slug"]))
          |> assign(:current_organisation, org)
          |> render("remove_user.html")
      end
    else
      not_found(conn)
    end
  end

  def delete(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case Repo.transaction(fn ->
            case OrganisationManager.delete_organisation(org) do
              {:ok, _} ->
                case GitManager.delete_dir(org.slug.slug) do
                  :ok ->
                    case GitManager.update_auth() do
                      :ok -> nil
                      error -> IO.inspect(error)
                    end
                    :ok
                  {:error, out} -> Repo.rollback(status: out)
                end
              {:error, e} -> Repo.rollback(e)
            end
          end) do
        {:ok, _} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :show, current_user.slug.slug))
        {:error, _} ->
          conn
          |> redirect(to: Routes.organisation_path(conn, :edit, org.slug.slug))
      end
    else
      not_found(conn)
    end
  end
end
