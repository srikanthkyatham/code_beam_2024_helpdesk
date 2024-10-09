defmodule HelpdeskWeb.AshJsonApiRouter do
  use AshJsonApi.Router,
    domains: [Helpdesk.Support],
    open_api: "/open_api"
end
