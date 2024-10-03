defmodule Helpdesk.Support.Ticket.Types.Attachment do
  use Ash.Resource,
    data_layer: :embedded,
    extensions: [
      AshJsonApi.Resource,
      Ash.Resource.Dsl
    ]

  alias Helpdesk.Support.Ticket.Types.FileType

  attributes do
    uuid_primary_key :id

    attribute :type, :string do
      allow_nil? false
      public? true
    end

    attribute :location, :string do
      allow_nil? false
      public? true
    end

    attribute :file_type, FileType do
      allow_nil? false
      public? true
    end
  end
end
