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

defmodule Kmxgit.OrganisationManager.UserOrganisation do

  use Ecto.Schema

  alias Kmxgit.OrganisationManager.Organisation
  alias Kmxgit.UserManager.User

  schema "users_organisations" do
    belongs_to :user, User
    belongs_to :organisation, Organisation
    belongs_to :invited_by, User, source: :invited_by
    field      :invited_at, :utc_datetime
    field      :invited_ip, :string
    timestamps()
  end

end
