defmodule KmxgitWeb.Admin.OrganisationController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.OrganisationManager
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager
  alias KmxgitWeb.ErrorView

  def index(conn, _params) do
    orgs = OrganisationManager.list_organisations
    conn
    |> assign(:orgs, orgs)
    |> render("index.html")
  end

  def new(conn, _params) do
    changeset = OrganisationManager.change_organisation
    conn
    |> assign(:action, Routes.admin_organisation_path(conn, :create))
    |> assign(:changeset, changeset)
    |> assign(:org, nil)
    |> render("new.html")
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    org_params = params["organisation"]
    case OrganisationManager.admin_create_organisation(org_params) do
      {:ok, org} ->
        conn
        |> redirect(to: Routes.admin_organisation_path(conn, :show, org))
      {:error, changeset} ->
        conn
        |> assign(:action, Routes.admin_organisation_path(conn, :create))
        |> assign(:changeset, changeset)
        |> assign(:org, nil)
        |> render("new.html")
    end
  end

  def show(conn, params) do
    org = OrganisationManager.get_organisation(params["id"])
    if org do
      conn
      |> assign(:org, org)
      |> render("show.html")
    else
      not_found(conn)
    end
  end

  def edit(conn, params) do
    org = OrganisationManager.get_organisation(params["id"])
    if org do
      changeset = OrganisationManager.change_organisation(org)
      conn
      |> assign(:action, Routes.admin_organisation_path(conn, :update, org))
      |> assign(:changeset, changeset)
      |> assign(:org, org)
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    org = OrganisationManager.get_organisation(params["id"])
    if org do
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
          |> redirect(to: Routes.admin_organisation_path(conn, :show, org1))
        {:error, changeset} ->
          conn
          |> assign(:action, Routes.admin_organisation_path(conn, :update, org))
          |> assign(:changeset, changeset)
          |> render("edit.html")
                    
      end
    else
      not_found(conn)
    end
  end

  def add_user(conn, params) do
    org = OrganisationManager.get_organisation!(params["organisation_id"])
    conn
    |> assign(:action, Routes.admin_organisation__path(conn, :add_user_post, org))
    |> assign(:org, org)
    |> render("add_user.html")
  end

  def add_user_post(conn, params) do
    login = params["organisation"]["login"]
    org = OrganisationManager.get_organisation!(params["organisation_id"])
    case OrganisationManager.add_user(org, login) do
      {:ok, org1} ->
        case GitManager.update_auth() do
          :ok -> nil
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.admin_organisation_path(conn, :show, org1))
      {:error, _} ->
        conn
        |> assign(:action, Routes.admin_organisation__path(conn, :add_user_post, org))
        |> assign(:org, org)
        |> render("add_user.html")
    end
  end

  def remove_user(conn, params) do
    org = OrganisationManager.get_organisation!(params["organisation_id"])
    conn
    |> assign(:action, Routes.admin_organisation__path(conn, :remove_user_post, org))
    |> assign(:org, org)
    |> render("remove_user.html")
  end

  def remove_user_post(conn, params) do
    login = params["organisation"]["login"]
    org = OrganisationManager.get_organisation!(params["organisation_id"])
    case OrganisationManager.remove_user(org, login) do
      {:ok, org} ->
        case GitManager.update_auth() do
          :ok -> nil
          error -> IO.inspect(error)
        end
        conn
        |> redirect(to: Routes.admin_organisation_path(conn, :show, org))
      {:error, _} ->
        conn
        |> assign(:action, Routes.admin_organisation__path(conn, :remove_user_post, org))
        |> assign(:org, org)
        |> render("remove_user.html")
    end
  end

  def delete(conn, params) do
    org = OrganisationManager.get_organisation(params["id"])
    if org do
      case OrganisationManager.delete_organisation(org) do
        {:ok, _} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.admin_organisation_path(conn, :index))
        {:error, _} ->
          conn
          |> redirect(to: Routes.admin_organisation_path(conn, :show, org))
      end
    else
      not_found(conn)
    end
  end
end
