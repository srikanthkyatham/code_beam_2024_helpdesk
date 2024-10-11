defmodule HelpdeskWeb.Live.SettingsLive.Index do
  @moduledoc false
  use Phoenix.LiveView
  import HelpdeskWeb.CoreComponents

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
    <h2 class="py-2 px-2 font-semibold"><%= @org_slug %></h2>
    <div class="px-4">
      <p>
        <bold class="font-medium">Api token:</bold>
        <%= @api_token %>
      </p>
      <ul class="py-2">
        <li><.link navigate={"/auth/#{@org_slug}/tickets"} class="underline">Tickets</.link></li>
        <li>
          <.link navigate={"/auth/#{@org_slug}/representatives"} class="underline">
            Representatives
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.header class="px-2">Settings</.header>
    <h3 class="py-2 px-2">Role <%= @role %></h3>
    <ul :for={org <- @orgs}>
      <.org_links org={org} current_user={@current_user} />
    </ul>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user |> Ash.load!([:orgs])
    orgs = current_user.orgs

    role =
      Helpdesk.Orgs.membership_of_user!(current_user.id).role |> Atom.to_string()

    {:ok,
     assign(socket, :orgs, orgs)
     |> assign(:role, role)}
  end
end
