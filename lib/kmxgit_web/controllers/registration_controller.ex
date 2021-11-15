defmodule KmxgitWeb.RegistrationController do
  use KmxgitWeb, :controller

  alias Kmxgit.{UserManager, UserManager.User, UserManager.Guardian}

  def new(conn, _) do
    changeset = UserManager.change_user(%User{})
    render(conn, "new.html", changeset: changeset,
      action: Routes.registration_path(conn, :register))
  end

  def register(conn, params) do
    case UserManager.create_user(params["user"]) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: User.after_register_path(user))
      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset,
                  action: Routes.registration_path(conn, :register))
    end
  end
end
