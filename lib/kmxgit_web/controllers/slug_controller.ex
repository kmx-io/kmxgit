defmodule KmxgitWeb.SlugController do
  use KmxgitWeb, :controller

  alias Kmxgit.RepositoryManager
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
        conn
        |> assign(:contributor_repos, RepositoryManager.list_contributor_repositories(user))
        |> assign(:owned_repos, User.owned_repositories(user))
        |> assign(:page_title, gettext("User %{login}", login: user.slug.slug))
        |> assign(:user, user)
        |> put_view(UserView)
        |> render("show.html")
      else
        org = slug.organisation
        if org do
          conn
          |> assign(:current_organisation, org)
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
