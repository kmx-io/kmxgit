## kmxgit
## Copyright 2022 kmx.io <contact@kmx.io>
##
## Permission is hereby granted to use this software granted
## the above copyright notice and this permission paragraph
## are included in all copies and substantial portions of this
## software.
##
## THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY GUARANTEE OF
## PURPOSE AND PERFORMANCE. IN NO EVENT WHATSOEVER SHALL THE
## AUTHOR BE CONSIDERED LIABLE FOR THE USE AND PERFORMANCE OF
## THIS SOFTWARE.

defmodule KmxgitWeb.Admin.RepositoryView do
  use KmxgitWeb, :view

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.UserManager.User

  def page_link(conn, title \\ nil, page) do
    link title || page, to: Routes.admin_repository_path(conn, :index, page: page, per: conn.assigns.pagination.per, search: conn.assigns.search, sort: conn.assigns.sort), class: "btn btn-primary"
  end
end
