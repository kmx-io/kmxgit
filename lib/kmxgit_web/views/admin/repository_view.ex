defmodule KmxgitWeb.Admin.RepositoryView do
  use KmxgitWeb, :view

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.UserManager.User

  def page_link(conn, title \\ nil, page) do
    link title || page, to: Routes.admin_repository_path(conn, :index, page: page, per: conn.assigns.pagination.per, search: conn.assigns.search, sort: conn.assigns.sort), class: "btn btn-primary"
  end
end
