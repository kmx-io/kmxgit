defmodule KmxgitWeb.PageController do
  use KmxgitWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
