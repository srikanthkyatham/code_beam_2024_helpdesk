defmodule Helpdesk.Orgs.Org do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Orgs,
    data_layer: AshPostgres.DataLayer

  require Ash.Query

  postgres do
    table "org"
    repo Helpdesk.Repo
  end

  actions do
    defaults [:read]

    read :org_by_slug do
      get? true
      argument :slug, :string, allow_nil?: false

      prepare fn query, context ->
        arg_slug = Ash.Query.get_argument(query, :slug)

        query
        |> Ash.Query.filter(slug == ^arg_slug)
      end
    end

    create :create do
      primary? true
      accept [:name, :slug]
    end
  end

  attributes do
    integer_primary_key :id
    attribute :name, :string, public?: true
    attribute :slug, :string, public?: true
  end

  relationships do
    many_to_many :users, Helpdesk.Accounts.User do
      through Helpdesk.Orgs.Membership
      source_attribute_on_join_resource :org_id
      destination_attribute_on_join_resource :user_id
    end
  end
end

defimpl Ash.ToTenant, for: Helpdesk.Orgs.Org do
  def to_tenant(value, _resource) do
    value
  end
end
