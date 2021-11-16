defmodule Kmxgit.OrganisationManager.Organisation do

  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :description, :string
    field :name, :string
    field :slug, :string, null: false
    timestamps()
  end

  @doc false
  def changeset(organisation, attrs \\ %{}) do
    organisation
    |> cast(attrs, [:slug, :description, :name])
    |> validate_required([:slug])
    |> validate_format(:slug, ~r/^[A-Za-z][-_+0-9A-Za-z]{1,64}$/)
    |> unique_constraint(:_lower_slug)
    |> Markdown.validate_markdown(:description)
  end

end
