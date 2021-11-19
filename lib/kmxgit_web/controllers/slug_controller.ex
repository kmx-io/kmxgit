defmodule KmxgitWeb.SlugController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager
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

  def delete(conn, params) do
    current_user = conn.assigns.current_user
    slug = SlugManager.get_slug(params["slug"])
    if slug do
      org = slug.organisation
      if org && Enum.find(org.users, &(&1.id == current_user.id)) do
        {:ok, _} = OrganisationManager.delete_organisation(org)
        conn
        |> redirect(to: Routes.slug_path(conn, :show, current_user.slug.slug))
      else
        not_found(conn)
      end
    else
      not_found(conn)
    end
  end
end
