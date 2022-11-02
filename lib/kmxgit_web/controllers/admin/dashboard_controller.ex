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

defmodule KmxgitWeb.Admin.DashboardController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager
  alias Kmxgit.RepositoryManager
  alias Kmxgit.UserManager

  def index(conn, _params) do
    conn
    |> assign(:org_count, OrganisationManager.count_organisations())
    |> assign(:page_title, gettext "Dashboard")
    |> assign(:repo_count, RepositoryManager.count_repositories())
    |> assign(:user_count, UserManager.count_users())
    |> render("index.html")
  end
end
