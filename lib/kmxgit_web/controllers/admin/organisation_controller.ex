defmodule KmxgitWeb.Admin.OrganisationController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager
  alias KmxgitWeb.ErrorView

  def index(conn, _params) do
    organisations = OrganisationManager.list_organisations
    conn
    |> assign(:organisations, organisations)
    |> render("index.html")
  end

  def new(conn, _params) do
    changeset = OrganisationManager.change_organisation
    conn
    |> assign(:action, Routes.admin_organisation_path(conn, :create))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    org_params = params["organisation"]
    Repo.transaction fn ->
      case SlugManager.create_slug(org_params["slug"]["slug"]) do
        {:ok, slug} ->
          case OrganisationManager.create_organisation(Map.merge(org_params, %{slug: slug, user: current_user})) do
            {:ok, org} ->
              conn
              |> redirect(to: Routes.admin_organisation_path(conn, :show, org))
            {:error, changeset} ->
              conn
              |> assign(:action, Routes.admin_organisation_path(conn, :create))
              |> assign(:changeset, changeset)
              |> render("new.html")
          end
        {:error, changeset} ->
          conn
          |> assign(:action, Routes.admin_organisation_path(conn, :create))
          |> assign(:changeset, changeset)
          |> render("new.html")
      end
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
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
    organisation = OrganisationManager.get_organisation(params["id"])
    if organisation do
      case OrganisationManager.update_organisation(organisation, params["organisation"]) do
        {:ok, org} ->
          conn
          |> redirect(to: Routes.admin_organisation_path(conn, :show, org))
        {:error, changeset} ->
          IO.inspect(changeset)
          conn
          |> assign(:action, Routes.admin_organisation_path(conn, :update, organisation))
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
      {:ok, org} ->
        conn
        |> redirect(to: Routes.admin_organisation_path(conn, :show, org))
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
    organisation = OrganisationManager.get_organisation(params["id"])
    if organisation do
      {:ok, _} = OrganisationManager.delete_organisation(organisation)
      conn
      |> redirect(to: Routes.admin_organisation_path(conn, :index))
    else
      not_found(conn)
    end
  end
end
