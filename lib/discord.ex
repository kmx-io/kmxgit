defmodule Discord do

  def error(conn, params) do
    uri = conn.request_uri
    user = conn.assigns[:current_user]
    webhook = Application.get_env(:kmxgit, :discord_errors_webhook)
    reason = if (try do params.reason.message rescue _ -> nil end) do
      type = params.reason.__struct__
      "#{type}: #{params.reason.message}"
    else
      inspect(params.reason)
    end
    stack = Stack.to_string(params.stack)
    message = %{content: "#{uri}\n#{user.slug.slug}\n```#{params.kind} #{reason}\n\n#{stack}```"}
    json = Jason.encode!(message)
    HTTPoison.post(webhook, json, [{"Content-Type", "application/json"}])
  end
end
