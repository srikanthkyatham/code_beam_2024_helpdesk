defmodule Helpdesk.Orgs.Membership do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Orgs,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "orgs_membership"
    repo Helpdesk.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:role, :user_id, :org_id]
    end

    update :assign do
      accept [:user_id, :org_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, Helpdesk.Orgs.Role do
      default :member
      allow_nil? false
    end
  end

  relationships do
    belongs_to :user, Helpdesk.Accounts.User do
      public? true
    end

    belongs_to :org, Helpdesk.Orgs.Org do
      attribute_type :integer
    end
  end
end
