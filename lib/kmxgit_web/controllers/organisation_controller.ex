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

defmodule KmxgitWeb.OrganisationController do
  use KmxgitWeb, :controller

  alias Kmxgit.GitAuth
  alias Kmxgit.GitManager
  alias Kmxgit.OrganisationManager
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Repo
  alias Kmxgit.SlugManager
  alias Kmxgit.UserManager.User

  def new(conn, _params) do
    _ = conn.assigns.current_user
    changeset = OrganisationManager.change_organisation
    conn
    |> assign(:action, Routes.organisation_path(conn, :create))
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user
    case Repo.transaction(fn ->
          case OrganisationManager.create_organisation(current_user, params["organisation"]) do
            {:ok, organisation} ->
              case SlugManager.create_slug(organisation) do
                {:ok, _slug} -> organisation
                {:error, err} ->
                  {message, _} = err.errors[:slug]
                  changeset = OrganisationManager.change_organisation(%Organisation{}, params["organisation"])
                  |> Ecto.Changeset.add_error(:slug_, message)
                  Repo.rollback(changeset)
              end
            {:error, err} -> Repo.rollback(err)
          end
        end) do
      {:ok, organisation} ->
        conn
        |> redirect(to: Routes.slug_path(conn, :show, organisation.slug_))
      {:error, changeset} ->
        IO.inspect(changeset)
        conn
        |> assign(:action, Routes.organisation_path(conn, :create))
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, params) do
    current_user = conn.assigns.current_user
    org =  OrganisationManager.get_organisation_by_slug(params["slug"])
    changeset = OrganisationManager.change_organisation(org)
    if org && Organisation.owner?(org, current_user) do
      conn
      |> assign(:action, Routes.organisation_path(conn, :update, org.slug_))
      |> assign(:changeset, changeset)
      |> assign(:current_organisation, org)
      |> render("edit.html")
    else
      not_found(conn)
    end
  end

  def update(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case Repo.transaction(fn ->
            case OrganisationManager.update_organisation(org, params["organisation"]) do
              {:ok, org1} ->
                if org.slug_ != org1.slug_ do
                  case SlugManager.rename_slug(org.slug_, org1.slug_) do
                    {:ok, _} ->
                      case GitManager.rename_dir(org.slug_, org1.slug_) do
                        :ok ->
                          GitAuth.update()
                          org1
                        {:error, err} -> Repo.rollback(err)
                      end
                    {:error, err} -> Repo.rollback(err)
                  end
                else
                  org1
                end
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end) do
        {:ok, org1} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org1.slug_))
        {:error, changeset} ->
          conn
          |> assign(:action, Routes.organisation_path(conn, :update, org.slug_))
          |> assign(:changeset, changeset)
          |> render("edit.html")
      end
    else
      not_found(conn)
    end
  end

  def add_user(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      conn
      |> assign(:action, Routes.organisation_path(conn, :add_user_post, params["slug"]))
      |> assign(:current_organisation, org)
      |> render("add_user.html")
    else
      not_found(conn)
    end
  end

  def add_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["organisation"]["login"]
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case OrganisationManager.add_user(org, login) do
        {:ok, org} ->
          GitAuth.update()
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org.slug_))
        {:error, _e} ->
          conn
          |> assign(:action, Routes.organisation_path(conn, :add_user_post, params["slug"]))
          |> assign(:current_organisation, org)
          |> render("add_user.html")
      end
    else
      not_found(conn)
    end
  end

  def remove_user(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      conn
      |> assign(:action, Routes.organisation_path(conn, :remove_user_post, params["slug"]))
      |> assign(:current_organisation, org)
      |> render("remove_user.html")
    else
      not_found(conn)
    end
  end

  def remove_user_post(conn, params) do
    current_user = conn.assigns.current_user
    login = params["organisation"]["login"]
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case OrganisationManager.remove_user(org, login) do
        {:ok, org} ->
          GitAuth.update()
          conn
          |> redirect(to: Routes.slug_path(conn, :show, org.slug_))
        {:error, _} ->
          conn
          |> assign(:action, Routes.organisation_path(conn, :remove_user_post, params["slug"]))
          |> assign(:current_organisation, org)
          |> render("remove_user.html")
      end
    else
      not_found(conn)
    end
  end

  def delete(conn, params) do
    current_user = conn.assigns.current_user
    org = OrganisationManager.get_organisation_by_slug(params["slug"])
    if org && Organisation.owner?(org, current_user) do
      case Repo.transaction(fn ->
            case OrganisationManager.delete_organisation(org) do
              {:ok, _} ->
                case SlugManager.delete_slug(org.slug_) do
                  :ok ->
                    case GitManager.delete_dir(org.slug_) do
                      :ok ->
                        GitAuth.update()
                        :ok
                      {:error, out} -> Repo.rollback(status: out)
                    end
                  {:error, e} -> Repo.rollback(e)
                end
              {:error, e} -> Repo.rollback(e)
            end
          end) do
        {:ok, _} ->
          conn
          |> redirect(to: Routes.slug_path(conn, :show, User.login(current_user)))
        {:error, err} ->
          IO.inspect(err)
          conn
          |> redirect(to: Routes.organisation_path(conn, :edit, org.slug_))
      end
    else
      not_found(conn)
    end
  end
end
