defmodule Helpdesk.Accounts.User do
  use Ash.Resource,
    otp_app: :helpdesk,
    domain: Helpdesk.Accounts,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication],
    data_layer: AshPostgres.DataLayer

  authentication do
    tokens do
      enabled? true
      token_resource Helpdesk.Accounts.Token
      signing_secret Helpdesk.Secrets
    end

    strategies do
      password :password do
        identity_field :email
      end
    end
  end

  postgres do
    table "users"
    repo Helpdesk.Repo
  end

  actions do
    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy always() do
      forbid_if always()
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false, public?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
  end

  relationships do
    belongs_to :org, Helpdesk.Orgs.Org do
      attribute_type :integer
      public? true
    end

    has_many :membership, Helpdesk.Orgs.Membership
  end

  identities do
    identity :unique_email, [:email]
  end
end
