defmodule KmxgitWeb.UserRegistrationController do
  use KmxgitWeb, :controller

  alias Kmxgit.Repo
  alias Kmxgit.SlugManager
  alias Kmxgit.UserManager
  alias Kmxgit.UserManager.User
  alias KmxgitWeb.UserAuth

  def new(conn, _params) do
    changeset = UserManager.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Repo.transaction(fn ->
          case UserManager.register_user(user_params) do
            {:ok, user} ->
              case SlugManager.create_slug(user) do
                {:ok, _slug} ->
                  {:ok, _} =
                    UserManager.deliver_user_confirmation_instructions(
                      user,
                      &Routes.user_confirmation_url(conn, :edit, &1))
                  user
                {:error, changeset} ->
                  Repo.rollback(changeset)
              end
            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)
      {:error, changeset} ->
        IO.inspect(changeset)
        render(conn, "new.html", changeset: changeset)
    end
  end
end
