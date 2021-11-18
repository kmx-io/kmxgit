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
      preload: :slug
    )
    user || raise Ecto.NoResultsError
  end

  def get_user(id) do
    Repo.one from user in User,
      where: [id: ^id],
      preload: [organisations: :slug],
      preload: :slug
  end

  def get_user_by_slug(slug) do
    Repo.one from u in User,
      join: s in Slug,
      on: s.id == u.slug_id,
      where: s.slug == ^slug,
      limit: 1
  end

  def create_user(slug, attrs \\ %{}) do
    %User{slug: slug}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def admin_create_user(slug, attrs \\ %{}) do
    %User{slug: slug}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
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

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def authenticate_user(login, password) do
    query = from u in User,
      where: fragment("lower(?)", u.login) == ^String.downcase(login) or fragment("lower(?)", u.email) == ^String.downcase(login)
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
