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

defmodule Markdown do

  def validate_markdown(changeset, field) do
    data = Map.get(changeset.changes, field,
      Map.get(changeset.data, field))
    if data do
      case Earmark.as_html(data) do
        {:ok, _, _} ->
          changeset
        {:error, _, error_messages} ->
          Ecto.Changeset.add_error(changeset, field, error_messages)
      end
    else
      changeset
    end
  end

  def to_html!(md) do
    Earmark.as_html!(md)
  end
end
