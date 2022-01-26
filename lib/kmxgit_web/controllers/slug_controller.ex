defmodule KmxgitWeb.SlugController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView
  alias KmxgitWeb.OrganisationView
  alias KmxgitWeb.UserView

  def show(conn, params) do
    slug = SlugManager.get_slug(params["slug"])
    if !slug do
      not_found(conn)
    else
      user = slug.user
      if user do
        owned_repos = User.owned_repositories(user)
        contributor_repos = RepositoryManager.list_contributor_repositories(user)
        repos = owned_repos ++ contributor_repos
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
          conn
          |> assign(:current_organisation, org)
          |> assign(:disk_usage, Organisation.disk_usage(org))
          |> assign(:org, org)
          |> assign(:page_title, org.name || org.slug.slug)
          |> put_view(OrganisationView)
          |> render("show.html")
        else
          not_found(conn)
        end
      end
    end
  end
end
