defmodule Kmxgit.UserManager.Avatar do
  import Mogrify

  @sizes [256, 48]

  def path(user, size) do
    dir = "priv/avatar/#{size}"
    File.mkdir_p(dir)
    "#{dir}/#{user.id}.png"
  end

  def set_image(user, path) do
    original = open(path)
    for size <- @sizes do
      original
      |> resize_to_fill("#{size}x#{size}")
      |> save(path: path(user, size))
    end
  end
end
