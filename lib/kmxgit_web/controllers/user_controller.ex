defmodule KmxgitWeb.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.Repo
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.ErrorView

  def edit(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == User.login(current_user) do
      user = current_user
      changeset = UserManager.change_user(user)
      email_changeset = UserManager.change_user_email(user)
      password_changeset = UserManager.change_user_password(user)
      conn
      |> assign(:changeset, changeset)
      |> assign(:email_changeset, email_changeset)
      |> assign(:page_title, gettext("Edit user %{login}", login: user.slug.slug))
      |> assign(:password_changeset, password_changeset)
      |> assign(:user, user)
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == User.login(current_user) do
      user = current_user
      case Repo.transaction(fn ->
            case UserManager.update_user(user, params["user"]) do
              {:ok, user} ->
                if user.slug.slug != user.slug.slug do
                  case GitManager.rename_dir(user.slug.slug, user.slug.slug) do
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
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
          conn
          |> redirect(to: Routes.slug_path(conn, :show, user.slug.slug))
        {:error, changeset} ->
          conn
          |> assign(:page_title, gettext("Edit user %{login}", login: user.slug.slug))
          |> assign(:changeset, changeset)
          |> assign(:user, user)
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end

  defp img_src_data(data, type) do
    "data:#{type};base64,#{Base.encode64(data)}"
  end

  defp totp_enrolment_qrcode_src(user) do
    UserManager.totp_enrolment_url(user)
    |> QRCodeEx.encode()
    |> QRCodeEx.svg()
    |> img_src_data("image/svg+xml")
  end

  def totp(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == User.login(current_user) do
      user = current_user
      changeset = UserManager.change_user(user)
      totp_enrolment_qrcode_src = totp_enrolment_qrcode_src(user)
      conn
      |> assign(:changeset, changeset)
      |> assign(:page_title, gettext("Activate TOTP for user %{login}", login: User.login(user)))
      |> assign(:totp_enrolment_qrcode_src, totp_enrolment_qrcode_src)
      |> assign(:user, user)
      |> render("totp.html")
    else
      not_found(conn)
    end
  end

  def totp_update(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == User.login(current_user) do
      user = current_user
      IO.inspect(params)
      case UserManager.update_user_totp(user, params["user"]) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "2FA (TOTP) was successfuly activated")
          |> redirect(to: Routes.slug_path(conn, :show, User.login(user)))
        {:error, changeset} ->
          totp_enrolment_qrcode_src = totp_enrolment_qrcode_src(user)
          conn
          |> assign(:changeset, changeset)
          |> assign(:page_title, gettext("Activate TOTP for user %{login}", login: User.login(user)))
          |> assign(:totp_enrolment_qrcode_src, totp_enrolment_qrcode_src)
          |> assign(:user, user)
          |> render("totp.html")
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
          case GitManager.update_auth() do
            :ok -> nil
            error -> IO.inspect(error)
          end
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
