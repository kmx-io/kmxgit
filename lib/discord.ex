defmodule Discord do

  def error(params) do
    url = Application.get_env(:kmxgit, :discord_errors_webhook)
    message = %{content: "```#{inspect(params)}```"}
    json = Jason.encode!(message)
    HTTPoison.post(url, json, [{"Content-Type", "application/json"}])
  end
end
