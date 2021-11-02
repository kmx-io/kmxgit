defmodule Kmxgit.Plug.EnsureAdmin do
  import Plug.Conn
  alias Kmxgit.UserManager.User

  def init(default), do: default

  def call(conn, _) do
    conn
    |> ensure_admin(Guardian.Plug.current_resource(conn))
  end

  defp ensure_admin(conn, user = %User{is_admin: true}) do
    conn
    |> assign(:current_admin_user, user)
  end

  defp ensure_admin(conn, _user) do
    body = "Forbidden"
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(403, body)
  end
end
