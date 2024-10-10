defmodule Helpdesk.Support.Ticket do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Support,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshJsonApi.Resource]

  alias Helpdesk.Support.Ticket.Types.Attachment

  json_api do
    type "ticket"
  end

  postgres do
    table "tickets"
    repo Helpdesk.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:subject, :status]
    end

    create :open do
      accept [:subject]
    end

    update :update do
      primary? true
      accept [:subject]
    end

    update :close do
      accept []

      validate attribute_does_not_equal(:status, :closed) do
        message "Ticket is already closed"
      end

      change set_attribute(:status, :closed)
    end

    update :assign do
      accept [:representative_id]
    end
  end

  policies do
    policy action(:destroy) do
      authorize_if Helpdesk.Checks.ActorIsAdmin
    end

    policy action_type([:create, :update, :read]) do
      authorize_if always()
    end
  end

  multitenancy do
    strategy :attribute
    attribute :org_id
  end

  attributes do
    uuid_primary_key :id

    attribute :subject, :string do
      allow_nil? false
      public? true
    end

    attribute :status, :ticket_status do
      default :open
      allow_nil? false
    end

    attribute :attachments, {:array, Attachment} do
      default []
      allow_nil? true
      public? true
    end
  end

  relationships do
    belongs_to :representative, Helpdesk.Support.Representative do
      public? true
    end

    belongs_to :org, Helpdesk.Orgs.Org do
      attribute_type :integer
    end
  end
end
