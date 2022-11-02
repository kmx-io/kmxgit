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
