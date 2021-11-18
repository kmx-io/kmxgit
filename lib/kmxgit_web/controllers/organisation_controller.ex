defmodule KmxgitWeb.OrganisationController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager

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
        IO.inspect(changeset)
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

  def show(conn, params) do
    org =  OrganisationManager.get_organisation_by_slug(params["slug"])
    if org do
      conn
      |> assign(:current_organisation, org)
      |> assign(:org, org)
      |> render("show.html")
    else
      not_found(conn)
    end
  end

  def edit(conn, params) do
    org =  OrganisationManager.get_organisation_by_slug(params["slug"])
    changeset = OrganisationManager.change_organisation(org)
    if org do
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
    organisation = OrganisationManager.get_organisation_by_slug(params["slug"])
    if organisation do
      case OrganisationManager.update_organisation(organisation, params["organisation"]) do
        {:ok, org} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org.slug.slug))
        {:error, changeset} ->
          IO.inspect(changeset)
          conn
          |> render("edit.html", changeset: changeset,
                    action: Routes.organisation_path(conn, :update, organisation.slug.slug))
      end
    else
      not_found(conn)
    end
  end
end
