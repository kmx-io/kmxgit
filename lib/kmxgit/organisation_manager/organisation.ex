defmodule Kmxgit.OrganisationManager.Organisation do

  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :slug, :string
    field :address, :string
    field :description, :string
    field :name, :string, null: false
    timestamps()
  end

  @doc false
  def changeset(organisation, attrs \\ %{}) do
    organisation
    |> cast(attrs, [:slug, :address, :description, :name])
    |> validate_required([:slug, :name])
    |> validate_format(:slug, ~r/^[A-Za-z][-_0-9A-Za-z]{1,64}$/)
    |> unique_constraint(:slug)
    |> Markdown.validate_markdown(:description)
  end

end
