defmodule HelpdeskWeb.Live.SettingsLive.Index do
  @moduledoc false
  use Phoenix.LiveView

  attr :org, :string, required: true
  attr :current_user, :any, required: true

  def org_links(assigns) do
    current_user = assigns.current_user

    update_current_user = %{
      current_user
      | __metadata__: Map.put(current_user.__metadata__, :tenant, assigns.org.id)
    }

    {:ok, api_token, _} = AshAuthentication.Jwt.token_for_user(update_current_user)
    assigns = assign(assigns, org_slug: assigns.org.slug, api_token: api_token)

    ~H"""
    <h2>Links of <%= @org_slug %></h2>
    <ul>
      <li><.link navigate={"/auth/#{@org_slug}/tickets"} class="underline">Tickets</.link></li>
      <li>
        <.link navigate={"/auth/#{@org_slug}/representatives"} class="underline">
          Representatives
        </.link>
      </li>
      <p>Api token</p>
      <p><%= @api_token %></p>
    </ul>
    """
  end

  def render(assigns) do
    ~H"""
    <ul :for={org <- @orgs}>
      <.org_links org={org} current_user={@current_user} />
    </ul>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user |> Ash.load!([:orgs])
    orgs = current_user.orgs

    is_admin =
      Helpdesk.Orgs.membership_of_user!(current_user.id)
      |> Helpdesk.Checks.ActorIsAdmin.is_admin?()

    {:ok,
     assign(socket, :orgs, orgs)
     |> assign(:admin, is_admin)}
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end
end
