defmodule KmxgitWeb.Admin.DashboardController do
  use KmxgitWeb, :controller

  def index(conn, _params) do
    conn
    |> assign(:page_title, gettext "Dashboard")
    |> render("index.html")
  end
end
