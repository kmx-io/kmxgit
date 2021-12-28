defmodule KmxgitWeb.UserSessionController do
  use KmxgitWeb, :controller

  alias Kmxgit.UserManager
  alias KmxgitWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"login" => login, "password" => password, "otp" => otp} = user_params
    if user = UserManager.get_user_by_login_and_password(login, password) do
      if user.otp_last == 0 || UserManager.verify_user_totp(user, otp) do
        UserAuth.log_in_user(conn, user, user_params)
      else
        conn
        |> assign(:error_message, "Invalid token")
        |> render("new.html")
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
