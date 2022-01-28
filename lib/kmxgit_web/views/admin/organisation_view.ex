defmodule KmxgitWeb.Admin.OrganisationView do
  use KmxgitWeb, :view

  alias Kmxgit.RepositoryManager.Repository

  def page_link(conn, title \\ nil, page) do
    link title || page, to: Routes.admin_organisation_path(conn, :index, page: page, per: conn.assigns.pagination.per, search: conn.assigns.search, sort: conn.assigns.sort), class: "btn btn-primary"
  end
end
