defmodule KmxgitWeb.PageController do
  use KmxgitWeb, :controller

  require Logger

  alias Kmxgit.GitManager
  alias Kmxgit.OrganisationManager
  alias Kmxgit.RepositoryManager
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.UserAuth

  def auth(conn, _params) do
    a = RepositoryManager.list_all_repositories()
    |> Enum.sort(fn a, b ->
      Repository.full_slug(a) < Repository.full_slug(b)
    end)
    |> Enum.map(fn repo -> Repository.auth(repo) end)
    |> Enum.join("\n")
    conn
    |> put_resp_content_type("text/text")
    |> resp(200, a)
  end

  def doc_git_install(conn, _) do
    conn
    |> render(:doc_git_install)
  end

  def index(conn, _params) do
    if ! UserManager.admin_user_present? do
      redirect(conn, to: Routes.page_path(conn, :new_admin))
    else
      conn
      |> assign(:discord, Application.get_env(:kmxgit, :discord))
      |> assign(:disk_usage, GitManager.du_ks("priv/git/"))
      |> assign(:git_ssh_url, Application.get_env(:kmxgit, :git_ssh_url))
      |> assign(:org_count, OrganisationManager.count_organisations())
      |> assign(:repo_count, RepositoryManager.count_repositories())
      |> assign(:user_count, UserManager.count_users())
      |> render(:index)
    end
  end

  def keys(conn, _params) do
    k1 = UserManager.list_all_users
    |> Enum.map(&User.ssh_keys_with_env/1)
    k2 = RepositoryManager.list_all_repositories
    |> Enum.map(&Repository.deploy_keys_with_env/1)
    k = (k1 ++ k2) |> Enum.join("\n")
    conn
    |> put_resp_content_type("text/text")
    |> resp(200, k)
  end

  def new_admin(conn, _params) do
    if ! UserManager.admin_user_present? do
      changeset = UserManager.change_user(%User{})
      conn
      |> assign(:action, Routes.page_path(conn, :new_admin))
      |> assign(:changeset, changeset)
      |> assign(:no_navbar_links, true)
      |> render("new_admin.html")
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
          |> UserAuth.log_in_user(user, user_params)
          |> redirect(to: "/")
          {:error, changeset} ->
            conn
            |> assign(:no_navbar_links, true)
            |> assign(:changeset, changeset)
            |> assign(:action, Routes.page_path(conn, :new_admin))
            |> render("new_admin.html")
      end
    else
      redirect(conn, to: "/")
    end
  end

  def privacy(conn, _params) do
    conn
    |> render(:privacy)
  end

  def robots(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> render("robots.txt")
  end

  def sitemap(conn, _params) do
    conn
    |> assign(:orgs, OrganisationManager.list_all_organisations())
    |> assign(:users, UserManager.list_all_users())
    |> put_resp_content_type("text/plain")
    |> render("sitemap.txt")
  end

  def user_agreement(conn, _params) do
    conn
    |> render(:user_agreement)
  end
end
