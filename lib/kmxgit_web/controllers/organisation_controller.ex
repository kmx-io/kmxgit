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
        |> redirect(to: Routes.organisation_path(conn, :show, organisation.slug))
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

  def show(conn, params) do
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org do
      conn
      |> assign(:current_org, org)
      |> assign(:org, org)
      |> render("show.html")
    else
      not_found(conn)
    end
  end
end
