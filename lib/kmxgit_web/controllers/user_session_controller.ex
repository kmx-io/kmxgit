defmodule KmxgitWeb.UserSessionController do
  use KmxgitWeb, :controller

  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, params = %{"user" => user_params}) do
    user_id = conn |> get_session(:check_totp_for)
    user = if user_id do
      {id, ""} = Integer.parse(user_id)
      UserManager.get_user(id)
    else
      %{"login" => login, "password" => password} = user_params
      UserManager.get_user_by_login_and_password(login, password)
    end
    totp = user_params["totp"]
    if user do
      if user.totp_last == 0 || totp && UserManager.verify_user_totp(user, totp) do
        UserAuth.log_in_user(conn, user, user_params)
      else
        changeset = UserManager.change_user(%User{}, user_params)
        conn
        |> put_session(:check_totp_for, Integer.to_string(user.id))
        |> assign(:changeset, changeset)
        |> assign(:error_message, "Invalid token")
        |> assign(:totp, totp)
        |> render("totp.html")
      end
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> assign(:error_message, "Invalid email or password")
      |> render("new.html")
    end
  end
  def create(conn, _params) do
    not_found(conn)
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "Logged out successfully.")
  end
end
