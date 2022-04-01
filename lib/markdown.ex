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
