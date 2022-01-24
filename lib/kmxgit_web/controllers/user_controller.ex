defmodule KmxgitWeb.UserController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitManager
  alias Kmxgit.Repo
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.{Avatar, User}
  alias KmxgitWeb.ErrorView

  def avatar(conn, %{"login" => login,
                     "size" => size}) do
    user = UserManager.get_user_by_login(login)
    if user do
      path = Avatar.path(user, size)
      conn
      |> put_resp_content_type("image/png")
      |> send_file(200, path)
    end
  end
  def avatar(conn, _) do
    not_found(conn)
  end

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
      avatar_param = params["user"]["avatar"]
      case Repo.transaction(fn ->
            case UserManager.update_user(user, params["user"]) do
              {:ok, user1} ->
                if User.login(user1) != User.login(user) do
                  case GitManager.rename_dir(User.login(user), User.login(user1)) do
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
          |> redirect(to: Routes.slug_path(conn, :show, User.login(user)))
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
      |> Ecto.Changeset.put_change(:totp_last, "")
      totp_enrolment_qrcode_src = totp_enrolment_qrcode_src(user)
      conn
      |> assign(:changeset, changeset)
      |> assign(:page_title, gettext("Enrol TOTP for user %{login}", login: User.login(user)))
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
          |> put_flash(:info, "Enroled 2FA (TOTP) successfuly.")
          |> redirect(to: Routes.slug_path(conn, :show, User.login(user)))
        {:error, changeset} ->
          totp_enrolment_qrcode_src = totp_enrolment_qrcode_src(user)
          conn
          |> assign(:changeset, changeset)
          |> assign(:page_title, gettext("Enrol TOTP for user %{login}", login: User.login(user)))
          |> assign(:totp_enrolment_qrcode_src, totp_enrolment_qrcode_src)
          |> assign(:user, user)
          |> render("totp.html")
      end
    else
      not_found(conn)
    end
  end

  def totp_delete(conn, params) do
    current_user = conn.assigns.current_user
    if params["login"] == User.login(current_user) do
      user = current_user
      case UserManager.delete_user_totp(user) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "Removed 2FA (TOTP) successfuly.")
          |> redirect(to: Routes.slug_path(conn, :show, User.login(user)))
        {:error, changeset} ->
          IO.inspect(changeset)
          conn
          |> put_flash(:error, "Failed to remove 2FA (TOTP).")
          |> redirect(to: Routes.user_path(conn, :edit, User.login(user)))
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
