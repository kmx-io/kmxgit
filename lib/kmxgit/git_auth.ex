defmodule Kmxgit.GitAuth do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    port = Port.open({:spawn_executable, "bin/update_auth"}, [:binary])
    {:ok, %{port: port}}
  end

  @impl true
  def handle_cast(:update, state = %{port: port}) do
    Port.command(port, "\n")
    {:noreply, state}
  end

  def update() do
    GenServer.cast(__MODULE__, :update)
  end
end
