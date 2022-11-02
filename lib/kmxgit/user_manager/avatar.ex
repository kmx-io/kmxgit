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
