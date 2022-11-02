## kmxgit
## Copyright 2022 kmx.io <contact@kmx.io>
##
## Permission is hereby granted to use this software granted
## the above copyright notice and this permission paragraph
## are included in all copies and substantial portions of this
## software.
##
## THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY GUARANTEE OF
## PURPOSE AND PERFORMANCE. IN NO EVENT WHATSOEVER SHALL THE
## AUTHOR BE CONSIDERED LIABLE FOR THE USE AND PERFORMANCE OF
## THIS SOFTWARE.

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
