defmodule Helpdesk.Orgs do
  use Ash.Domain

  resources do
    resource Helpdesk.Orgs.Org
    resource Helpdesk.Orgs.Membership
  end
end
