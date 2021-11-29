defmodule KmxgitWeb.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.Repo
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def edit(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == current_user.slug.slug do
      changeset = User.changeset(current_user)
      conn
      |> assign(:changeset, changeset)
      |> assign(:page_title, gettext("Edit user %{login}", login: current_user.slug.slug))
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == current_user.slug.slug do
      case Repo.transaction(fn ->
            case UserManager.update_user(current_user, params["user"]) do
              {:ok, user} ->
                if user.slug.slug != current_user.slug.slug do
                  case GitManager.rename_dir(current_user.slug.slug, user.slug.slug) do
                    :ok -> user
                    {:error, err} -> Repo.rollback(err)
                  end
                else
                  user
                end
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end) do
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

  def delete(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == current_user.slug.slug do
      case Repo.transaction(fn ->
            case UserManager.delete_user(current_user) do
              {:ok, _} ->
                case GitManager.delete_dir(current_user.slug.slug) do
                  :ok -> :ok
                  {:error, out} -> Repo.rollback(status: out)
                end
              {:error, e} -> Repo.rollback(e)
            end
          end) do
        {:ok, _} ->
          conn
          |> redirect(to: "/")
        {:error, changeset} ->
          conn
          |> assign(:changeset, changeset)
          |> assign(:page_title, gettext("Edit user %{login}", login: current_user.slug.slug))
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end
end
