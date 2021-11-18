defmodule KmxgitWeb.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView

  def show(conn, params) do
    current_user = conn.assigns[:current_user]
    user = if current_user && params["login"] == current_user.slug.slug do
      current_user
    else
      UserManager.get_user_by_slug(params["login"])
    end
    if user do
      conn
      |> assign(:page_title, gettext("User %{login}", login: user.slug.slug))
      |> assign(:user, user)
      |> render("show.html")
    else
      conn
      |> not_found()
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def edit(conn, params) do
    current_user = conn.assigns[:current_user]
    if params["login"] == current_user.slug.slug do
      changeset = User.changeset(current_user)
      conn
      |> assign(:page_title, gettext("Edit user %{login}", login: current_user.slug.slug))
      |> render("edit.html", changeset: changeset)
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns[:current_user]
    if params["login"] == current_user.slug.slug do
      case UserManager.update_user(current_user, params["user"]) do
        {:ok, user} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :show, user.slug.slug))
        {:error, changeset} ->
          conn
          |> assign(:page_title, gettext("Edit user %{login}", login: current_user.slug.slug))
          |> assign(:changeset, changeset)
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end
end
