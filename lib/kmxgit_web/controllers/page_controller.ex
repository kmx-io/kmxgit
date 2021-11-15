defmodule KmxgitWeb.PageController do
  use KmxgitWeb, :controller

  alias Kmxgit.OrganisationManager
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
      case UserManager.admin_create_user(user_params) do
        {:ok, user} ->
          conn
          |> Guardian.Plug.sign_in(user)
          |> redirect(to: "/")
        {:error, changeset} ->
          IO.inspect(changeset)
          conn
          |> assign(:no_navbar_links, true)
          |> render("new_admin.html", changeset: changeset,
                    action: Routes.page_path(conn, :new_admin))
      end
    else
      redirect(conn, to: "/")
    end
  end
end
