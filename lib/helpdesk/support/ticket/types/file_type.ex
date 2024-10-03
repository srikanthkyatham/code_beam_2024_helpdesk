defmodule Helpdesk.Support.Ticket.Types.FileType do
  use Ash.Type.Enum, values: [:pdf, :txt]
end
