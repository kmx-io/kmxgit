defmodule KmxgitWeb.ErrorController do
  use KmxgitWeb, :controller

  def show(conn, params) do
    code = params["code"]
    case code do
      ["500"] -> raise "Testing error 500 from controller."
      ["500", "view"] -> render(conn, :"500")
      ["500", "assign"] -> render(conn, :assign)
      _ -> not_found(conn)
    end
  end
end
