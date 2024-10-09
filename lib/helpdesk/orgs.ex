defmodule Helpdesk.Orgs do
  use Ash.Domain

  resources do
    resource Helpdesk.Orgs.Org do
      define :org_by_slug, action: :org_by_slug, args: [:slug]
      # define :orgs_of_user, action: :orgs_of_user, args: [:user]
      define :create_org, action: :create, args: [:name, :slug]
    end

    resource Helpdesk.Orgs.Membership do
      define :create_membership, action: :create, args: [:role, :user_id, :org_id]
    end
  end

  # api to get Org by id
  # documentation read
end
