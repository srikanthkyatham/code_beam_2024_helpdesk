defmodule Helpdesk.Orgs do
  use Ash.Domain

  resources do
    resource Helpdesk.Orgs.Org do
      define :org_by_slug, action: :org_by_slug, args: [:slug]
    end

    resource Helpdesk.Orgs.Membership do
      define :create_membership, action: :create, args: [:role, :user_id, :org_id]
    end
  end

  # api to get Org by id
  # documentation read
end
