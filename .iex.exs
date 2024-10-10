defmodule AshHelpers do
  @moduledoc false
  #   iex> AshHelpers.create_resource(Org, [name: "org2", slug: "org2"], nil)
  def create_resource(module, params, tenant) do
    module
    |> Ash.Changeset.for_create(:create, params,
      actor: %{},
      authorize?: true,
      tenant: tenant
    )
    |> Ash.create()
  end

  def create_user_token(user) do
    AshAuthentication.Jwt.token_for_user(user)
  end
end
