defmodule KmxgitWeb.SlugController do
  use KmxgitWeb, :controller

  alias Kmxgit.SlugManager
  alias KmxgitWeb.ErrorView
  alias KmxgitWeb.OrganisationView
  alias KmxgitWeb.UserView

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def show(conn, params) do
    slug = SlugManager.get_slug(params["slug"])
    if !slug do
      not_found(conn)
    else
      user = slug.user
      if user do
        conn
        |> assign(:page_title, gettext("User %{login}", login: user.slug.slug))
        |> assign(:user, user)
        |> render(UserView, "show.html")
      else
        org = slug.organisation
        if org do
          conn
          |> assign(:current_organisation, org)
          |> assign(:org, org)
          |> render(OrganisationView, "show.html")
        else
          not_found(conn)
        end
      end
    end
  end
end
