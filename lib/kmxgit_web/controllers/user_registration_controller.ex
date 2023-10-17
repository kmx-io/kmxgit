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

  defp merge_errors(changeset, errors) do
    %Ecto.Changeset{changeset | errors: changeset.errors ++ errors,
                    action: :insert,
                    valid?: false}
  end

  def create(conn, %{"user" => user_params}) do
    case Repo.transaction(fn ->
          error_changeset = %User{}
          |> User.registration_changeset(user_params)
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
                  IO.inspect(changeset)
                  error_changeset
                  |> merge_errors(changeset.errors)
                  |> Repo.rollback()
              end
            {:error, changeset} ->
              IO.inspect(changeset)
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
