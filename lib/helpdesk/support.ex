defmodule Helpdesk.Support do
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      # in the domain `base_route` acts like a scope
      base_route "/tickets", Helpdesk.Support.Ticket do
        get :read
        index :read
        post :open
      end
    end
  end

  resources do
    resource Helpdesk.Support.Ticket
    resource Helpdesk.Support.Representative
  end
end
