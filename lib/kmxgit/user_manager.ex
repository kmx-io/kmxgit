defmodule Kmxgit.UserManager do
  @moduledoc """
  The UserManager context.
  """

  import Ecto.Query, warn: false

  alias Kmxgit.Repo
  alias Kmxgit.SlugManager.Slug
  alias Kmxgit.UserManager.{User, UserToken, UserNotifier}

  def list_users do
    Repo.all from user in User, preload: :slug
  end

  def get_user(id) do
    Repo.one from user in User,
      where: [id: ^id],
      preload: [organisations: :slug],
      preload: [owned_repositories: [organisation: :slug, user: :slug]],
      preload: :slug
  end

  def get_user!(id) do
    get_user(id) || raise Ecto.NoResultsError
  end

  def get_user_by_login(login) do
    Repo.one from u in User,
      join: s in Slug,
      on: s.user_id == u.id,
      where: fragment("lower(?)", s.slug) == ^String.downcase(login),
      limit: 1,
      preload: [:slug,
                organisations: :slug,
                owned_repositories: [organisation: :slug,
                                     user: :slug]]
  end

  def get_user_by_login_and_password(login, password)
  when is_binary(login) and is_binary(password) do
    user = get_user_by_login(login)
    if User.valid_password?(user, password), do: user
  end

  def get_user_by_email(email) do
    Repo.one from u in User,
      where: u.email == ^email,
      limit: 1,
      preload: [:slug,
                organisations: :slug,
                owned_repositories: [organisation: :slug,
                                     user: :slug]]
  end

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_email(user, token) do
    old = user.email
    context = "change:#{user.email}"
    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)),
         _ <- UserNotifier.deliver_email_changed_email(old, email) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
  when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
         {:ok, %{user: user}} ->
           UserNotifier.deliver_password_changed_email(user)
           {:ok, user}
         {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    user = Repo.one(query)
    if user do
      get_user(user.id)
    end
  end

  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def admin_create_user(attrs \\ %{}) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    old_login = user.slug.slug
    case user
         |> User.changeset(attrs)
         |> Repo.update() do
      {:ok, u} ->
        if u.slug.slug != old_login do
          UserNotifier.deliver_login_changed_email(u, old_login, u.slug.slug)
        end
        {:ok, u}
      x -> x
    end
  end

  def admin_update_user(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  def admin_update_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    user
    |> change_user()
    |> Repo.delete()
  end

  def change_user(%User{} = user \\ %User{}, params \\ %{}) do
    User.changeset(user, params)
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

  def totp_init do
    Repo.transaction fn ->
      Enum.each list_users(), fn u ->
        {:ok, _} = User.totp_changeset(u) |> Repo.update()
      end
    end
  end

  @doc """
  Returns a URL that be rendered with a QR code.
  It meets the Google Authenticator specification
  at https://github.com/google/google-authenticator/wiki/Key-Uri-Format.
  ## Examples
      iex> generate_totp_enrolment_url(user)
  """
  def totp_enrolment_url(%User{email: email, totp_secret: secret}) do
    "otpauth://totp/kmxgit:#{email}?secret=#{secret}&issuer=kmxgit&algorithm=SHA1&digits=6&period=30"
  end

  def update_user_totp(user = %User{}, params) do
    user
    |> User.totp_changeset(params)
    |> Repo.update()
  end

  def verify_user_totp(user = %User{}, token) do
    User.totp_verify(user, token || 0)
  end

  def delete_user_totp(user = %User{}) do
    user
    |> User.totp_changeset(:delete)
    |> Repo.update()
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
