defmodule KmxgitWeb.PageController do
  use KmxgitWeb, :controller

  alias Kmxgit.Repo
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.{Guardian, User}

  def index(conn, _params) do
    if ! UserManager.admin_user_present? do
      redirect(conn, to: Routes.page_path(conn, :new_admin))
    else
      conn
      |> render(:index)
    end
  end

  def new_admin(conn, _params) do
    if ! UserManager.admin_user_present? do
      changeset = UserManager.change_user(%User{})
      conn
      |> assign(:no_navbar_links, true)
      |> render("new_admin.html", changeset: changeset,
                action: Routes.page_path(conn, :new_admin))
    else
      redirect(conn, to: "/")
    end
  end

  def new_admin_post(conn, params) do
    if ! UserManager.admin_user_present? do
      user_params = Map.merge(params["user"], %{"is_admin" => true})
      Repo.transaction fn ->
        case UserManager.admin_create_user(user_params) do
          {:ok, user} ->
            conn
            |> Guardian.Plug.sign_in(user)
            |> redirect(to: "/")
          {:error, changeset} ->
            conn
            |> assign(:no_navbar_links, true)
            |> assign(:changeset, changeset)
            |> assign(:action, Routes.page_path(conn, :new_admin))
            |> render("new_admin.html")
        end
      end
    else
      redirect(conn, to: "/")
    end
  end

  def keys(conn, params) do
    k = UserManager.list_users
    |> Enum.map(fn user -> User.ssh_keys_with_env(user) end)
    |> Enum.join("\n")
    conn
    |> put_resp_content_type("text/text")
    |> resp(200, k)
  end
end
