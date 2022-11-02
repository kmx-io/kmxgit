defmodule Mix.Tasks.Licence do
  use Mix.Task

  def update(src_path, dest) do
    module = case src_path do
               "Makefile" -> Header.Make
               "configure" -> Header.Make
               "config.subr" -> Header.Make
               _ ->
                 case Regex.run(~r/[.][ch]$/, src_path) do
                   [_] -> Header.C
                   _ ->
                     case Regex.run(~r/[.]exs?$/, src_path) do
                       [_] -> Header.Make
                       _ -> raise "error"
                     end
                 end
             end
    module.main(dest)
  end

  def run(_) do
    {c_files, 0} = System.cmd("find", ["c_src", "-name", "[a-z]*.c",
                                       "-or", "-name", "[a-z]*.h"])
    {ex_files, 0} = System.cmd("find", ["lib", "-name", "[a-z]*.ex",
                                        "-or", "-name", "[a-z]*.exs"])
    c_files = c_files |> String.split("\n") |> Enum.filter(& &1 != "")
    ex_files = ex_files |> String.split("\n") |> Enum.filter(& &1 != "")
    update("c_src/git_nif.c", c_files)
    update("lib/kmxgit.ex", ex_files)
  end
end
