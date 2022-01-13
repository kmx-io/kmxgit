defmodule Kmxgit.Repo.Migrations.ChangeOtpToTotp do
  use Ecto.Migration

  def change do
    rename table(:users), :otp_last, to: :totp_last
    rename table(:users), :otp_secret, to: :totp_secret
  end
end
