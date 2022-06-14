defmodule KmxgitWeb.SlugController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView
  alias KmxgitWeb.OrganisationView
  alias KmxgitWeb.UserView

  def show(conn, params) do
    current_user = conn.assigns.current_user
    slug = SlugManager.get_slug(params["slug"])
    if !slug do
      not_found(conn)
    else
      user = slug.user
      if user do
        owned_repos = User.owned_repositories(user)
        contributor_repos = RepositoryManager.list_contributor_repositories(user)
        repos = owned_repos ++ contributor_repos
        |> Enum.filter(fn repo ->
          repo.public_access || Repository.member?(repo, current_user)
        end)
        conn
        |> assign(:disk_usage, User.disk_usage(user))
        |> assign(:disk_usage_all, Repository.disk_usage(repos))
        |> assign(:repos, repos)
        |> assign(:page_title, gettext("User %{login}", login: User.login(user)))
        |> assign(:user, user)
        |> put_view(UserView)
        |> render("show.html")
      else
        org = slug.organisation
        if org do
          repos = org.owned_repositories
          |> Enum.filter(fn repo ->
            repo.public_access || Repository.member?(repo, current_user)
          end)
          |> Enum.sort(fn a, b ->
            a.slug < b.slug
          end)
          conn
          |> assign(:current_organisation, org)
          |> assign(:disk_usage, Organisation.disk_usage(org))
          |> assign(:org, org)
          |> assign(:page_title, org.name || org.slug.slug)
          |> assign(:repos, repos)
          |> put_view(OrganisationView)
          |> render("show.html")
        else
          not_found(conn)
        end
      end
    end
  end
end
