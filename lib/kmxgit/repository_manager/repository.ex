defmodule Kmxgit.RepositoryManager.Repository do

  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User

  schema "repositories" do
    field :description, :string
    belongs_to :organisation, Organisation
    field :slug, :string, unique: true
    belongs_to :user, User
    timestamps()
  end

  def changeset(repository, attrs \\ %{}) do
    repository
    |> cast(attrs, [:description, :slug])
    |> validate_required([:slug])
    |> validate_format(:slug, ~r|^[A-Za-z][-_+.0-9A-Za-z]{1,64}(/[A-Za-z][-_+.0-9A-Za-z]{1,64})*$|)
    |> unique_constraint(:_lower_slug)
    |> Markdown.validate_markdown(:description)
  end

end
