defmodule Helpdesk.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Helpdesk.Accounts.User, _opts) do
    Application.fetch_env(:helpdesk, :token_signing_secret)
  end
end
