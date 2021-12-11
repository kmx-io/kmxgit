defmodule KmxgitWeb.Admin.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.RepositoryManager
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView

  def index(conn, _params) do
    users = UserManager.list_users
    conn
    |> assign(:page_title, gettext("Users"))
    |> assign(:users, users)
    |> render("index.html")
  end

  def show(conn, params) do
    user = UserManager.get_user(params["id"])
    if user do
      owned_repos = User.owned_repositories(user)
      contributor_repos = RepositoryManager.list_contributor_repositories(user)
      repos = owned_repos ++ contributor_repos
      conn
      |> assign(:page_title, gettext("User %{login}", login: user.slug.slug))
      |> assign(:repos, repos)
      |> assign(:user, user)
      |> render("show.html")
    else
      not_found(conn)
    end
  end

  def edit(conn, params) do
    user = UserManager.get_user(params["id"])
    if user do
      changeset = UserManager.change_user(user)
      conn
      |> assign(:changeset, changeset)
      |> assign(:user, user)
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    user = UserManager.get_user(params["id"])
    if user do
      case UserManager.admin_update_user(user, params["user"]) do
        {:ok, user1} ->
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.admin_user_path(conn, :show, user1))
        {:error, changeset} ->
          conn
          |> assign(:changeset, changeset)
          |> assign(:user, user)
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end

  def edit_password(conn, params) do
    user = UserManager.get_user(params["user_id"])
    if user do
      changeset = UserManager.change_user(user)
      conn
      |> assign(:changeset, changeset)
      |> assign(:user, user)
      |> render("edit_password.html")
    else
      not_found(conn)
    end
  end

  def update_password(conn, params) do
    user = UserManager.get_user(params["user_id"])
    if user do
      case UserManager.admin_update_user_password(user, params["user"]) do
        {:ok, user1} ->
          conn
          |> redirect(to: Routes.admin_user_path(conn, :show, user1))
        {:error, changeset} ->
          conn
          |> assign(:changeset, changeset)
          |> assign(:user, user)
          |> render("edit_password.html")
      end
    else
      not_found(conn)
    end
  end

  def delete(conn, params) do
    if user = UserManager.get_user(params["id"]) do
      {:ok, _} = UserManager.delete_user(user)
      case GitManager.update_auth() do
        :ok -> nil
        error -> IO.inspect(error)
      end
      conn
      |> redirect(to: Routes.admin_user_path(conn, :index))
    else
      not_found(conn)
    end
  end
end
