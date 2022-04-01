defmodule Pygmentize do

  def random_string() do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
  end

  def lexer(filename) do
    {out, status} = System.cmd("pygmentize", ["-N", filename |> String.replace(~r/ /, "_")])
    case status do
      0 -> out |> String.trim()
      _ -> ""
    end
  end
    
  def html(content, filename) do
    lexer = lexer(filename)
    cmd = "./bin/size #{byte_size(content)} pygmentize -l #{lexer} -f html"
    IO.inspect(cmd)
    port = Port.open({:spawn, cmd}, [:binary, :use_stdio, :exit_status, :stderr_to_stdout])
    Port.monitor(port)
    send(port, {self(), {:command, content}})
    html_port(content, port, [])
  end

  def html_port(content, port, acc) do
    receive do
      {^port, {:exit_status, 0}} ->
        acc |> Enum.reverse() |> Enum.join()
      {^port, {:exit_status, status}} ->
        IO.inspect("pygmentize exited with status #{status}")
        nil
      {^port, {:data, data}} ->
        html_port(content, port, [data | acc])
      {:DOWN, _, :port, ^port, reason} ->
        IO.inspect({:down, reason})
        acc |> Enum.reverse() |> Enum.join()
      x ->
        IO.inspect(x)
        html_port(content, port, acc)
    after 1000 ->
        result = acc |> Enum.reverse() |> Enum.join()
        if result == "" do
          nil
        else
          result
        end
    end
  end
end
