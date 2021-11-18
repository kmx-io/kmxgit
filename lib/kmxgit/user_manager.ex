defmodule Kmxgit.UserManager do
  @moduledoc """
  The UserManager context.
  """

  import Ecto.Query, warn: false

  alias Kmxgit.Repo
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager.User

  alias Bcrypt

  def list_users do
    Repo.all from user in User, preload: :slug
  end

  def get_user!(id) do
    user = Repo.one(from user in User,
      where: [id: ^id],
      preload: [organisations: :slug],
      preload: :repositories,
      preload: :slug
    )
    user || raise Ecto.NoResultsError
  end

  def get_user(id) do
    Repo.one from user in User,
      where: [id: ^id],
      preload: [organisations: :slug],
      preload: :repositories,
      preload: :slug
  end

  def get_user_by_slug(slug) do
    Repo.one from u in User,
      join: s in Slug,
      on: s.id == u.slug_id,
      where: fragment("lower(?)", s.slug) == ^String.downcase(slug),
      limit: 1
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def admin_create_user(attrs \\ %{}) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def admin_update_user(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def authenticate_user(login, password) do
    query = from u in User,
      join: s in Slug,
      on: s.user_id == u.id,
      where: fragment("lower(?)", s.slug) == ^String.downcase(login) or fragment("lower(?)", u.email) == ^String.downcase(login),
      limit: 1
    case Repo.one(query) do
      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
      user ->
        if Bcrypt.verify_pass(password, user.encrypted_password) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def admin_user_present? do
    if Repo.one(from user in User,
          where: [is_admin: true],
          limit: 1) do
      true
    else
      false
    end
  end
end
