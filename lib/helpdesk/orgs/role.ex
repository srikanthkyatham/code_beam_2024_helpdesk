defmodule Helpdesk.Orgs.Role do
  use Ash.Type.Enum, values: [:member, :admin]
end
