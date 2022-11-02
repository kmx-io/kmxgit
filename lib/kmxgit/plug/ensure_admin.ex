## kmxgit
## Copyright 2022 kmx.io <contact@kmx.io>
##
## Permission is hereby granted to use this software granted
## the above copyright notice and this permission paragraph
## are included in all copies and substantial portions of this
## software.
##
## THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY GUARANTEE OF
## PURPOSE AND PERFORMANCE. IN NO EVENT WHATSOEVER SHALL THE
## AUTHOR BE CONSIDERED LIABLE FOR THE USE AND PERFORMANCE OF
## THIS SOFTWARE.

defmodule Kmxgit.Plug.EnsureAdmin do
  import Plug.Conn
  alias Kmxgit.UserManager.User

  def init(default), do: default

  def call(conn, _) do
    conn
    |> ensure_admin(conn.assigns.current_user)
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
