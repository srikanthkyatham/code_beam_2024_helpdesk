defmodule Helpdesk.Support.Ticket do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Support,
    data_layer: AshPostgres.DataLayer

  alias Helpdesk.Support.Ticket.Types.Attachment

  postgres do
    table "tickets"
    repo Helpdesk.Repo

    # manage_tenant do
    #  template(["org_", :id])
    # end
  end

  actions do
    defaults [:read]

    create :create do
      accept [:subject]
    end

    create :open do
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
  end
end
