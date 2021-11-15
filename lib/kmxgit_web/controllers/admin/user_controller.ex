defmodule KmxgitWeb.Admin.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.UserManager
  alias KmxgitWeb.ErrorView

  def index(conn, _params) do
    users = UserManager.list_users
    conn
    |> assign(:users, users)
    |> render("index.html")
  end

  def show(conn, params) do
    user = UserManager.get_user(params["id"])
    show_user(conn, user)
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  defp show_user(conn, nil) do
    not_found(conn)
  end

  defp show_user(conn, user) do
    conn
    |> assign(:user, user)
    |> render("show.html")
  end

  def edit(conn, params) do
    user = UserManager.get_user(params["id"])
    edit_user(conn, user)
  end

  defp edit_user(conn, nil) do
    not_found(conn)
  end

  defp edit_user(conn, user) do
    changeset = UserManager.change_user(user)
    conn
    |> render("edit.html", user: user, changeset: changeset)
  end

  def update(conn, params) do
    user = UserManager.get_user(params["id"])
    update_user(conn, user, params)
  end

  defp update_user(conn, nil, _params) do
    not_found(conn)
  end

  defp update_user(conn, user, params) do
    case UserManager.admin_update_user(user, params["user"]) do
      {:ok, _updated_user} ->
        conn
        |> redirect(to: Routes.admin_user_path(conn, :show, user))
      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, params) do
    user = UserManager.get_user(params["id"])
    delete_user(conn, user)
  end

  defp delete_user(conn, nil) do
    not_found(conn)
  end
    
  defp delete_user(conn, user) do
    {:ok, _} = UserManager.delete_user(user)
    conn
    |> redirect(to: Routes.admin_user_path(conn, :index))
  end

end
