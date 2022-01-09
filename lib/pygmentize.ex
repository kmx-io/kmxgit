defmodule Pygmentize do

  def random_string() do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
  end

  def html(content, filename) do
    dir = "#{System.tmp_dir()}/#{random_string()}"
    File.mkdir_p(dir)
    path = "#{dir}/#{filename}"
    File.write(path, content)
    {out, status} = System.cmd("pygmentize", ["-f", "html", path], stderr_to_stdout: true)
    output = case status do
      0 -> out
      _ -> nil
    end
    File.rm_rf(dir)
    output
  end

  def get_reply(port, state) do
    ref = state.ref
    receive do
      {^port, {:data, msg}} ->
        state = Map.put(state, :content, [msg | state.content])
        get_reply(port, state)
      {:DOWN, ^ref, :port, _port, :normal} ->
        Enum.reverse(state.output)
      msg ->
        IO.inspect([msg: msg])
        get_reply(port, state)
    end
  end
end
