defmodule KmxgitWeb.Admin.DashboardController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.OrganisationManager
  alias Kmxgit.RepositoryManager
  alias Kmxgit.UserManager

  def index(conn, _params) do
    conn
    |> assign(:disk_usage, GitManager.du_ks("priv/git"))
    |> assign(:org_count, OrganisationManager.count_organisations())
    |> assign(:page_title, gettext "Dashboard")
    |> assign(:repo_count, RepositoryManager.count_repositories())
    |> assign(:user_count, UserManager.count_users())
    |> render("index.html")
  end
end
