defmodule KmxgitWeb.SessionController do
  use KmxgitWeb, :controller

  alias Kmxgit.{UserManager, UserManager.User}

  def new(conn, params) do
    changeset = UserManager.change_user(%User{})
    user = UserManager.Guardian.Plug.current_resource(conn)
    if user do
      redirect(conn, to: params["redirect"] || User.after_login_path(user))
    else
      redirect = params["redirect"]
      action = if redirect do
        Routes.session_path(conn, :login, redirect: redirect)
      else
        Routes.session_path(conn, :login)
      end
      render(conn, "new.html", changeset: changeset, action: action)
    end
  end

  def login(conn, params = %{"user" => %{"login" => login,
                                         "password" => password}}) do
    redirect = params["redirect"] || "/"
    conn
    |> login_reply(UserManager.authenticate_user(login, password), redirect)
  end

  def logout(conn, _params) do
    conn
    |> UserManager.Guardian.Plug.sign_out()
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp login_reply(conn, {:ok, user}, redirect) do
    conn
    |> UserManager.Guardian.Plug.sign_in(user)
    |> redirect(to: redirect || User.after_login_path(user))
  end

  defp login_reply(conn, {:error, reason}, _redirect) do
    conn
    |> put_flash(:error, to_string(reason))
    |> new(%{})
  end

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body = to_string(type)
    case conn.request_path do
      "/sessions/new" ->
        conn
        |> put_view(KmxgitWeb.SessionView)
        |> put_layout({KmxgitWeb.LayoutView, "app.html"})
        |> put_flash(:error, body)
        |> new(conn.params)
        |> halt()
      "/sessions/login" ->
        conn
        |> put_view(KmxgitWeb.SessionView)
        |> put_layout({KmxgitWeb.LayoutView, "app.html"})
        |> put_flash(:error, body)
        |> login(conn.params)
        |> halt()
      _ ->
        conn
        |> put_flash(:error, body)
        |> redirect(to: Routes.session_path(conn, :new, redirect: current_path(conn)        |> halt()
))
    end
  end
end
