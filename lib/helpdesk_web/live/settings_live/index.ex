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
    Current temperature: <%= @temperature %>°F <button phx-click="inc_temperature">+</button>
    <ul :for={org <- @orgs}>
      <.org_links org={org} current_user={@current_user} />
    </ul>
    """
  end

  def mount(_params, _session, socket) do
    # get the orgs of the user
    current_user = socket.assigns.current_user |> Ash.load!([:orgs])
    # %{selected: [:id, :email, :hashed_password], keyset: "g2o="}

    orgs = current_user.orgs

    temperature = 0
    # orgs from the user ??

    {:ok,
     assign(socket, :temperature, temperature)
     |> assign(:orgs, orgs)}
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end
end
