defmodule Helpdesk.Accounts do
  use Ash.Domain

  resources do
    resource Helpdesk.Accounts.Token
    resource Helpdesk.Accounts.User
  end
end
