defmodule KmxgitWeb.RegistrationController do
  use KmxgitWeb, :controller

  alias Kmxgit.{UserManager, UserManager.User, UserManager.Guardian}

  def new(conn, _) do
    changeset = UserManager.change_user(%User{})
    conn
    |> assign(:action, Routes.registration_path(conn, :register))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def register(conn, params) do
    case UserManager.create_user(params["user"]) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: Routes.slug_path(conn, :show, user.slug.slug))
      {:error, changeset} ->
        conn
        |> assign(:action, Routes.registration_path(conn, :register))
        |> assign(:changeset, changeset)
        |> render("new.html")
                  
    end
  end
end
