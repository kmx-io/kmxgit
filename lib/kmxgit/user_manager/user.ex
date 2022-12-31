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

defmodule Kmxgit.UserManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Kmxgit.Git
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.RepositoryManager.Repository
  alias Kmxgit.SlugManager.Slug
  alias BCrypt

  schema "users" do
    field :confirmed_at, :utc_datetime
    field :deploy_only, :boolean, default: false
    field :description, :string
    field :disk_usage, :integer, default: 0
    field :email, :string
    field :hashed_password, :string, redact: true
    field :is_admin, :boolean, default: false
    field :name, :string
    many_to_many :organisations, Organisation, join_through: "users_organisations", on_delete: :delete_all
    has_many :owned_repositories, Repository, on_delete: :delete_all
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    many_to_many :repositories, Repository, join_through: "users_repositories", on_delete: :delete_all
    has_one :slug, Slug, on_delete: :delete_all
    field :slug_, :string
    field :ssh_keys, :string
    field :totp_last, :integer, default: 0, redact: true
    field :totp_secret, :string, redact: true
    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :name, :password, :slug_])
    |> generate_totp_secret()
    |> validate_email()
    |> validate_password(opts)
    |> common_changeset()
  end

  def totp_changeset(user) do
    user
    |> cast(%{}, [])
    |> generate_totp_secret()
    |> common_changeset()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Kmxgit.Repo)
    |> unique_constraint(:email)
  end

  defp maybe_validate_password(changeset, opts) do
    p = changeset.changes[:password]
    if p && p != "" do
      changeset
      |> validate_password(opts)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[0-9]/, message: "at least one digit")
    |> validate_format(:password, ~r([-_+*/\\.:;,=!?@#$%^'"&\(\)\[\]<>°§]), message: "at least one special character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  defp common_changeset(changeset) do
    changeset
    |> validate_required([:deploy_only, :email, :hashed_password, :is_admin, :totp_secret, :slug_])
    |> validate_email()
    |> Markdown.validate_markdown(:description)
    |> foreign_key_constraint(:owned_repositories, name: :repositories_user_id_fkey)
    |> validate_format(:slug_, ~r/^[A-Za-z][-_+.0-9A-Za-z]{1,64}$/)
  end

  defp generate_totp_secret(changeset) do
    secret = :crypto.strong_rand_bytes(10) |> Base.encode32()
    put_change(changeset, :totp_secret, secret)
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:deploy_only, :description, :name, :slug_, :ssh_keys])
    |> common_changeset()
  end

  def admin_changeset(user, attrs \\ %{}, opts \\ []) do
    user
    |> cast(attrs, [:deploy_only, :description, :email, :is_admin, :name, :password, :slug_, :ssh_keys, :totp_last, :totp_secret])
    |> validate_email()
    |> maybe_validate_password(opts)
    |> common_changeset()
  end

  def admin_create_user_changeset(user, attrs \\ %{}, opts \\ []) do
    user
    |> cast(attrs, [:deploy_only, :description, :email, :is_admin, :name, :password, :slug_, :ssh_keys])
    |> generate_totp_secret()
    |> validate_email()
    |> maybe_validate_password(opts)
    |> common_changeset()
  end

  def display_name(user) do
    user.name || login(user)
  end

  def ssh_keys_with_env(user) do
    (user.ssh_keys || "")
    |> String.split("\n")
    |> Enum.map(fn line ->
      line1 = String.replace(line, "\r", "")
      if Regex.match?(~r/^[ \t]*ssh-/, line1) do
        "environment=\"GIT_AUTH_ID=#{login(user)}\" #{line1}"
      else
        line1
      end
    end)
    |> Enum.join("\n")
  end

  def owned_repositories(user) do
    user.owned_repositories
    |> Enum.sort_by(&Repository.full_slug/1)
  end

  def login(user) do
    user.slug_
  end

  def totp_verify(%__MODULE__{totp_secret: secret}, token) do
    :pot.valid_totp(token, secret, [window: 1, addwindow: 1])
  end

  def totp_changeset(user, :delete) do
    user
    |> cast(%{totp_last: 0}, [:totp_last])
  end
  def totp_changeset(user, params) do
    user
    |> cast(params, [:totp_last])
    |> verify_totp_last()
  end

  defp verify_totp_last(changeset) do
    totp_last = changeset |> get_field(:totp_last) |> Integer.to_string()
    if totp_verify(changeset.data, totp_last) do
      changeset
    else
      changeset
      |> add_error(:totp_last, "invalid token")
    end
  end

  def disk_usage(user) do
    Git.dir_disk_usage(login(user))
  end
end
