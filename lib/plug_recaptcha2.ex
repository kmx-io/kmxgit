defmodule PlugRecaptcha2 do
  import Plug.Conn

  def init(default), do: default

  def call(conn, [recaptcha_secret: secret,
                  redirect: redirect]) do
    case conn do
      %Plug.Conn{params: %{"recaptcha" => signature}} ->
        case verify_signature(signature, secret) do
          {:ok} -> conn
          _ -> halt_connection(conn, redirect)
        end
      _ ->
        # IO.puts "no recaptcha param"
        halt_connection(conn, redirect)
    end
  end
  def call(conn, [recaptcha_secret: secret]) do
    call(conn, [recaptcha_secret: secret,
                redirect: nil])
  end
  def call(_conn, _opts), do: raise "Recaptcha Secret is missing"

  defp verify_signature(signature, secret) do
    post_url = "https://www.google.com/recaptcha/api/siteverify?secret=#{secret}&response=#{signature}"
    resp = HTTPoison.post(post_url, "", [{"Content-Type", "application/json"}])
    IO.inspect(recaptcha: resp)
    case resp do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode(body)
        |> verify_response
      _ -> {:fail}
    end
  end

  defp verify_response({:ok, %{"success" => true}}), do: {:ok}
  defp verify_response(_), do: {:fail}

  defp halt_connection(conn, redirect) do
    url = hd(get_req_header(conn, "referer")) || redirect || "/"
    conn
    |> Phoenix.Controller.redirect(external: url)
  end
end
