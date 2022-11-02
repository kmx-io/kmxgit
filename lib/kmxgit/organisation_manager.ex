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

defmodule Kmxgit.OrganisationManager do

  import Ecto.Query, warn: false

  alias Kmxgit.IndexParams
  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.Pagination
  alias Kmxgit.Repo
  alias Kmxgit.UserManager

  def list_all_organisations() do
    from(org in Organisation)
    |> order_by([org], [asc_nulls_last: org.slug_])
    |> preload([:owned_repositories, :slug])
    |> Repo.all()
  end

  def list_organisations(params \\ %IndexParams{}) do
    update_disk_usage()
    from(org in Organisation)
    |> search(params)
    |> index_order_by(params)
    |> Pagination.page(params, preload: [:owned_repositories])
  end

  def search(query, %IndexParams{search: search}) do
    expr = "%#{search}%"
    query
    |> where([org], ilike(org.name, ^expr) or ilike(org.slug_, ^expr))
  end

  def index_order_by(query, %{column: "id", reverse: true}) do
    order_by(query, [desc: :id])
  end
  def index_order_by(query, %{column: "name", reverse: true}) do
    order_by(query, [org], [desc_nulls_last: fragment("lower(?)", org.name)])
  end
  def index_order_by(query, %{column: "name"}) do
    order_by(query, [org], [asc_nulls_last: fragment("lower(?)", org.name)])
  end
  def index_order_by(query, %{column: "slug", reverse: true}) do
    order_by(query, [org], [desc_nulls_last: org.slug_])
  end
  def index_order_by(query, %{column: "slug"}) do
    order_by(query, [org], [asc_nulls_last: org.slug_])
  end
  def index_order_by(query, %{column: "du", reverse: true}) do
    order_by(query, [desc: :disk_usage])
  end
  def index_order_by(query, %{column: "du"}) do
    order_by(query, :disk_usage)
  end
  def index_order_by(query, _) do
    order_by(query, :id)
  end

  def update_disk_usage() do
    Repo.all(from org in Organisation)
    |> Enum.map(fn org ->
      org
      |> Ecto.Changeset.cast(%{}, [])
      |> Ecto.Changeset.put_change(:disk_usage, Organisation.disk_usage(org))
      |> Repo.update!()
    end)
  end

  def put_disk_usage(org = %Organisation{}) do
    %Organisation{org | disk_usage: Organisation.disk_usage(org)}
  end
  def put_disk_usage(orgs) when is_list(orgs) do
    orgs
    |> Enum.map(&put_disk_usage/1)
  end

  def count_organisations do
    Repo.one from org in Organisation, select: count()
  end

  def get_organisation(id) do
    Repo.one from organisation in Organisation,
      where: [id: ^id],
      preload: [:users,
                owned_repositories: [:organisation,
                                     :user]],
      limit: 1
  end

  def get_organisation!(id) do
    get_organisation(id) || raise Ecto.NoResultsError
  end

  def change_organisation(organisation \\ %Organisation{}, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end

  def create_organisation(user, attrs \\ %{}) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:users, [user])
    |> Repo.insert()
  end

  def update_organisation(organisation, attrs \\ %{}) do
    organisation
    |> Organisation.changeset(attrs)
    |> Repo.update()
  end

  def get_organisation_by_slug(slug) do
    Repo.one from o in Organisation,
      where: o.slug_ == ^slug,
      preload: [:users,
                owned_repositories: [:organisation,
                                     :user]],
      limit: 1
  end

  def add_user(%Organisation{} = org, login) do
    user = UserManager.get_user_by_login(login)
    if user do
      users = [user | org.users]
      org
      |> Organisation.changeset(%{})
      |> Ecto.Changeset.put_assoc(:users, users)
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  def remove_user(%Organisation{} = org, login) do
    user = UserManager.get_user_by_login(login)
    if user do
      users = Enum.reject(org.users, &(&1.id == user.id))
      org
      |> Organisation.changeset(%{})
      |> Ecto.Changeset.put_assoc(:users, users)
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  def delete_organisation(%Organisation{} = organisation) do
    organisation
    |> Organisation.changeset(%{})
    |> Repo.delete()
  end

  def admin_create_organisation(attrs \\ %{}) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Repo.insert()
  end

  def update_slug_() do
    for org <- list_all_organisations() do
      if (org.slug) do
        update_organisation(org, %{slug_: org.slug.slug})
      else
        delete_organisation(org)
      end
    end
  end
end
