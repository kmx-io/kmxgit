defmodule Kmxgit.Git do
  use GenServer

  @git_root "priv/git"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Functions

  def branches(repo) do
    GenServer.call(__MODULE__, {:branches, repo})
    |> String.trim()
    |> String.split(" ")
  end

  # Callbacks

  @impl true
  def init(_) do
    cmd = {:spawn_executable, "bin/gitport"}
    IO.inspect(cmd)
    port = Port.open(cmd, [:binary])
    {:ok, %{from: [], port: port}}
  end
  
  @impl true
  def handle_call(arg = {:branches, repo}, from, state) do
    IO.inspect({:handle_cast, arg})
    dir = git_dir(repo)
    cmd = "branches #{dir}\n"
    send(state.port, {self(), {:command, cmd}})
    {:noreply, %{state | from: state.from ++ [from]}}
  end

  @impl true
  def handle_info(arg = {port, {:data, data}}, state = %{from: [from | rest], port: port}) do
    GenServer.reply(from, data)
    {:noreply, %{state | from: rest}}
  end
  def handle_info(arg, state) do
    {:noreply, %{state | from: tl(state.from)}}
  end

  # common functions

  def git_dir(repo) do
    if String.match?(repo, ~r/(^|\/)\.\.($|\/)/), do: raise "invalid git dir"
    "#{@git_root}/#{repo}.git"
  end
end
