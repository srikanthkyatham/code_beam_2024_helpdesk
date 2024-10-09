defmodule HelpdeskWeb.UserAuth do
  @moduledoc """
  A set of plugs related to user authentication.
  This module is imported into the router and thus any function can be called there as a plug.
  """
  use HelpdeskWeb, :verified_routes
  import Plug.Conn

  def put_tenant(conn, _opts) do
    tenant = conn.query_params["tenant"]

    if tenant != nil do
      Ash.PlugHelpers.set_tenant(conn, tenant)
    else
      conn
    end
  end

  def get_actor_from_ash_token(conn, _opts) do
    # before retrieve is called
    # someone should verify jwt token and set tent

    otp_app = :helpdesk

    conn =
      conn
      |> retrieve_tenant_from_bearer(otp_app)
      |> AshAuthentication.Plug.Helpers.retrieve_from_bearer(otp_app)

    current_user = Map.get(conn.assigns, :current_user)
    conn
  end

  def retrieve_tenant_from_bearer(conn, otp_app) do
    conn
    |> Plug.Conn.get_req_header("authorization")
    |> Stream.filter(&String.starts_with?(&1, "Bearer "))
    |> Stream.map(&String.replace_leading(&1, "Bearer ", ""))
    |> Enum.reduce(conn, fn token, conn ->
      with {:ok, %{"tenant" => tenant}, _} <- AshAuthentication.Jwt.verify(token, otp_app) do
        Ash.PlugHelpers.set_tenant(conn, tenant)
      else
        _ -> conn
      end
    end)
  end
end