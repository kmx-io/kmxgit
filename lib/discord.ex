defmodule Discord do

  def error(params) do
    url = Application.get_env(:kmxgit, :discord_errors_webhook)
    reason = if (params.reason.message rescue nil) do
      type = params.reason.__struct__
      "#{type}: #{params.reason.message}"
    else
      inspect(params.reason)
    end
    stack = Stack.to_string(params.stack)
    message = %{content: "```#{params.kind} #{reason}\n\n#{stack}```"}
    json = Jason.encode!(message)
    HTTPoison.post(url, json, [{"Content-Type", "application/json"}])
  end
end
