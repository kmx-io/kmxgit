defmodule Discord do

  def error(params) do
    channel = Application.get_env(:kmxgit, :discord_errors_channel)
    url = "https://discord.com/api/webhooks/938739293336240139/rwlm6amtl8aGWyDt1iZtUa__HISah8KQeNuWD3_UrVTyZjxcAn6UGaZ3EJ0Rq2pt4_5e"
    message = %{content: inspect(params)}
    json = Jason.encode!(message)
    HTTPoison.post(url, json, [{"Content-Type", "application/json"}])
  end
end
