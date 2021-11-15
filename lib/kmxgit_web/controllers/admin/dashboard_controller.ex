defmodule KmxgitWeb.Admin.DashboardController do
  use KmxgitWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
