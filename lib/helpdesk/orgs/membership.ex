defmodule Helpdesk.Orgs.Membership do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Orgs,
    data_layer: AshPostgres.DataLayer

  require Ash.Query

  postgres do
    table "orgs_membership"
    repo Helpdesk.Repo
  end

  actions do
    defaults [:read]

    read :membership_of_user do
      get? true
      argument :user_id, :string, allow_nil?: false

      prepare fn query, context ->
        arg_user_id = Ash.Query.get_argument(query, :user_id)

        query
        |> Ash.Query.load([:user, :org])
        |> Ash.Query.filter(user.id == ^arg_user_id)
      end
    end

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
