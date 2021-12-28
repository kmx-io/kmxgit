defmodule Kmxgit.Repo.Migrations.AddOtpToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :otp_last, :integer, null: false, default: 0
      add :otp_secret, :string
    end
  end
end
