defmodule Discord do

  def headers_to_string(headers), do: headers_to_string(headers, [])
  def headers_to_string([], acc), do: acc |> Enum.reverse() |> Enum.join("\n")
  def headers_to_string([{name, value} | rest], acc) do
    headers_to_string(rest, ["#{name}: #{value}" | acc])
  end

  def error(conn, params) do
    IO.inspect(conn)
    req_path = conn.request_path
    user = if conn.assigns[:current_user] do
      conn.assigns.current_user.slug.slug
    else
      "_anonymous"
    end
    webhook = Application.get_env(:kmxgit, :discord_errors_webhook)
    reason = if (try do params.reason.message rescue _ -> nil end) do
      type = params.reason.__struct__
      "#{type}: #{params.reason.message}"
    else
      inspect(params.reason)
    end
    stack = Stack.to_string(params.stack)
    headers = headers_to_string(conn.req_headers)
    message = %{content: """
URI : #{req_path}
User : #{user}
```#{params.kind} #{reason}

#{stack}```
Headers :
```#{headers}```
"""}
    json = Jason.encode!(message)
    HTTPoison.post(webhook, json, [{"Content-Type", "application/json"}])
  end
end
