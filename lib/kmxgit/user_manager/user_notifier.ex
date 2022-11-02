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

defmodule Kmxgit.UserManager.UserNotifier do
  import Swoosh.Email

  alias Kmxgit.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"kmxgit", Application.fetch_env!(:kmxgit, :mail_from)})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """
    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """
    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """
    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.
    """)
  end

  def deliver_login_changed_email(user, old_login, new_login) do
    deliver(user.email, "Your login was changed", """
    Hi #{user.email},

    Your login was changed from #{old_login} to #{new_login}.

    If you didn't request this change, please reply to this e-mail.
    """)
  end

  defp email_changed_email_body(email, old, new) do
    """
    Hi #{email},

    Your e-mail address was changed from #{old} to #{new}.

    If you didn't request this change, please reply to this e-mail.
    """
  end

  def deliver_email_changed_email(old, new) do
    subject = "Your email address was changed"
    deliver(old, subject, email_changed_email_body(old, old, new))
    deliver(new, subject, email_changed_email_body(new, old, new))
  end

  def deliver_password_changed_email(user) do
    deliver(user.email, "Your password was changed", """
    Hi #{user.email},

    Your password was changed.

    If you didn't request this change, please reply to this e-mail.
    """)
  end

  def deliver_totp_enabled_email(user) do
    deliver(user.email, "TOTP was enabled", """
    Hi #{user.email},

    TOTP (Google Authenticator) has been activated on your account.
    You will need to enter a new TOTP each time you login in addition
    to login / password.

    If you didn't request this change, please reply to this e-mail.
    """)
  end


  def deliver_totp_disabled_email(user) do
    deliver(user.email, "TOTP was disabled !", """
    Hi #{user.email},

    TOTP (Google Authenticator) has been disabled on your account.
    You will no longer need to enter a new TOTP each time you login.

    If you didn't request this change, please reply to this e-mail.
    """)
  end
end
