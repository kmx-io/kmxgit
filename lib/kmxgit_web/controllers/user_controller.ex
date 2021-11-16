defmodule KmxgitWeb.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView

  def show(conn, params) do
    current_user = conn.assigns[:current_user]
    user = if current_user && params["login"] == current_user.login do
      current_user
    else
      UserManager.get_user_by_login(params["login"])
    end
    if user do
      conn
      |> assign(:page_title, gettext("User %{login}", login: user.login))
      |> render("show.html", user: user)
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
    if params["login"] == current_user.login do
      changeset = User.changeset(current_user)
      conn
      |> assign(:page_title, gettext("Edit user %{login}", login: current_user.login))
      |> render("edit.html", changeset: changeset)
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns[:current_user]
    if params["login"] == current_user.login do
      case UserManager.update_user(current_user, params["user"]) do
        {:ok, user} ->
          conn
          |> redirect(to: Routes.user_path(conn, :show, user.login))
        {:error, changeset} ->
          conn
          |> render("edit.html", changeset: changeset)
      end
    else
      not_found(conn)
    end
  end
end
