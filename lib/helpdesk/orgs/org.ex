defmodule Helpdesk.Orgs.Org do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Orgs,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizations"
    repo Helpdesk.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :name, :string, public?: true
    attribute :slug, :string, public?: true
  end

  relationships do
    has_many :membership, Helpdesk.Orgs.Membership
  end
end

defimpl Ash.ToTenant, for: Helpdesk.Orgs.Org do
  def to_tenant(value, _resource) do
    value
  end
end
