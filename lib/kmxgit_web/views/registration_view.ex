defmodule KmxgitWeb.RegistrationView do
  use KmxgitWeb, :view

  def recaptcha_site_key do
    Application.get_env :kmxgit, :recaptcha_site_key
  end
end
