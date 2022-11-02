## kmxgit
## Copyright 2022 kmx.io <contact@kmx.io>
##
## Permission is hereby granted to use this software granted
## the above copyright notice and this permission paragraph
## are included in all copies and substantial portions of this
## software.
##
## THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY GUARANTEE OF
## PURPOSE AND PERFORMANCE. IN NO EVENT WHATSOEVER SHALL THE
## AUTHOR BE CONSIDERED LIABLE FOR THE USE AND PERFORMANCE OF
## THIS SOFTWARE.

defmodule KmxgitWeb.Admin.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.IndexParams
  alias Kmxgit.GitAuth
  alias Kmxgit.GitManager
  alias Kmxgit.Repo
  alias Kmxgit.RepositoryManager
  alias Kmxgit.SlugManager
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView

  def index(conn, params) do
    index_params = %IndexParams{}
    |> KmxgitWeb.Admin.page_params(params["page"], params["per"])
    |> KmxgitWeb.Admin.search_param(params["search"])
    |> KmxgitWeb.Admin.sort_param(params["sort"])
    pagination = UserManager.list_users(index_params)
    conn
    |> assign(:index, index_params)
    |> assign(:page_title, gettext("Users"))
    |> assign(:pagination, pagination)
    |> assign(:search, params["search"])
    |> assign(:search_action, Routes.admin_user_path(conn, :index, sort: params["sort"], search: params["search"]))
    |> assign(:sort, params["sort"])
    |> render("index.html")
  end

  def new(conn, _params) do
    changeset = UserManager.change_user()
    conn
    |> assign(:action, Routes.admin_user_path(conn, :create))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, params) do
    pw = :crypto.strong_rand_bytes(16) |> Base.url_encode64()
    pw = "Az0!#{pw}"
    user_params = Map.merge(params["user"], %{"password" => pw})
    case UserManager.admin_create_user(user_params) do
      {:ok, user} ->
        conn
        |> redirect(to: Routes.admin_user_path(conn, :show, user))
      {:error, changeset} ->
        IO.inspect changeset
        conn
        |> assign(:action, Routes.admin_user_path(conn, :create))
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def show(conn, params) do
    user = UserManager.get_user(params["id"])
    if user do
      user = user
      |> UserManager.put_disk_usage()
      owned_repos = User.owned_repositories(user)
      contributor_repos = RepositoryManager.list_contributor_repositories(user)
      repos = owned_repos ++ contributor_repos
      conn
      |> assign(:page_title, gettext("User %{login}", login: User.login(user)))
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
      case Repo.transaction(fn ->
            case UserManager.admin_update_user(user, params["user"]) do
              {:ok, user1} ->
                if user.slug_ != user1.slug_ do
                  case SlugManager.rename_slug(user.slug_, user1.slug_) do
                    {:ok, _slug} ->
                      case GitManager.rename_dir(user.slug_, user1.slug_) do
                        :ok ->
                          GitAuth.update()
                          user1
                        {:error, err} -> Repo.rollback(err)
                      end
                    {:error, err} -> Repo.rollback(err)
                  end
                else
                  user1
                end
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end) do
        {:ok, user1} ->
          conn
          |> redirect(to: Routes.admin_user_path(conn, :show, user1))
        {:error, changeset} ->
          IO.inspect(changeset)
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
      GitAuth.update()
      conn
      |> redirect(to: Routes.admin_user_path(conn, :index))
    else
      not_found(conn)
    end
  end
end
