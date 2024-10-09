defmodule HelpdeskWeb.Live.SettingsLive.Index do
  @moduledoc false
  use Phoenix.LiveView

  # <li><.link navigate={~p"/auth/tickets"} class="underline">Tickets</.link></li>
  # <li><.link navigate={~p"/auth/representatives"} class="underline">Representatives</.link></li>

  def render(assigns) do
    ~H"""
    Current temperature: <%= @temperature %>°F <button phx-click="inc_temperature">+</button>
    <ul></ul>
    """
  end

  def mount(_params, _session, socket) do
    # get the orgs of the user
    current_user = socket.assigns.current_user

    Ash.load(current_user, [:memberships]) |> dbg()
    socket.assigns.current_user |> dbg()
    temperature = 0
    # orgs from the user ??

    {:ok, assign(socket, :temperature, temperature)}
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end
end
