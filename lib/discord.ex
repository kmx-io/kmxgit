defmodule Discord do

  def headers_to_string(headers), do: headers_to_string(headers, [])
  def headers_to_string([], acc), do: acc |> Enum.reverse() |> Enum.join("\n")
  def headers_to_string([{name, value} | rest], acc) do
    headers_to_string(rest, ["#{name}: #{value}" | acc])
  end

  def error(conn, params) do
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
    stack = Errors.stack_to_string(params.stack)
    no_reason = error_message(req_path, user, params, "", nil)
    reason_max_len = 2000 - String.length(no_reason)
    discord_reason = reason |> String.slice(0..reason_max_len)
    no_stack = error_message(req_path, user, params, discord_reason, nil)
    stack_max_len = 2000 - String.length(no_stack) - 8
    content = if stack_max_len > 0 do
      stack = stack |> String.slice(0..stack_max_len)
      error_message(req_path, user, params, discord_reason, stack)
    else
      no_stack
    end
    message = %{content: content}
    IO.inspect(message)
    json = Jason.encode!(message)
    HTTPoison.post(webhook, json, [{"Content-Type", "application/json"}])
    |> IO.inspect()
  end

  def error_message(req_path, user, params, reason, stack) do
    """
URI : `#{req_path}`
User : `#{user}`
#{params.kind} :
```#{reason}```#{if stack do "\n\nStack : ```#{stack}```" end}
"""
  end
end
