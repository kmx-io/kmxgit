defmodule KmxgitWeb.OrganisationController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager

  def index(conn, _params) do
    organisations = OrganisationManager.list_organisations
    conn
    |> render("index.html", organisations: organisations)
  end

  def show(conn, params) do
    organisation = OrganisationManager.get_organisation_by_slug(params["slug"])
    conn
    |> assign(:current_organisation, organisation)
    |> render("show.html", organisation: organisation)
  end
end
