defmodule Discord do

  def error(params) do
    channel = Application.get_env(:kmxgit, :discord_errors_channel)
    url = "/channels/#{channel}/messages"
    message = %{content: inspect(params)}
    json = Jason.encode!(message)
    HTTPoison.post url json [{"Content-Type", "application/json"}]
  end
end
