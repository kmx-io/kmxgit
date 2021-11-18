defmodule KmxgitWeb.LayoutView do
  use KmxgitWeb, :view

  def flash_json(conn) do
    {:ok, result} = Jason.encode(get_flash(conn))
    %{"data-flash": result}
  end

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}
end
