defmodule KmxgitWeb.Admin.OrganisationController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager
  alias Kmxgit.OrganisationManager.Organisation
  alias KmxgitWeb.ErrorView

  def index(conn, _params) do
    organisations = OrganisationManager.list_organisations
    conn
    |> render("index.html", organisations: organisations)
  end

  def new(conn, _params) do
    changeset = OrganisationManager.change_organisation(%Organisation{})
    conn
    |> assign(:action, Routes.admin_organisation_path(conn, :create))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, params) do
    case OrganisationManager.create_organisation(params["organisation"]) do
      {:ok, organisation} ->
        conn
        |> redirect(to: Routes.organisation_path(conn, :show, organisation.slug))
      {:error, changeset} ->
          IO.inspect(changeset)
          conn
          |> render("new.html", changeset: changeset,
                    action: Routes.admin_organisation_path(conn, :create))
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def show(conn, params) do
    organisation = OrganisationManager.get_organisation(params["id"])
    if organisation do
      conn
      |> render("show.html", organisation: organisation)
    else
      not_found(conn)
    end
  end

  def edit(conn, params) do
    organisation = OrganisationManager.get_organisation(params["id"])
    if organisation do
      changeset = OrganisationManager.change_organisation(organisation)
      conn
      |> render("edit.html", changeset: changeset,
      action: Routes.admin_organisation_path(conn, :update, organisation))
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
          |> render("edit.html", changeset: changeset,
                    action: Routes.admin_organisation_path(conn, :update, organisation))
      end
    else
      not_found(conn)
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
