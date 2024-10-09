defmodule HelpdeskWeb.Router do
  use HelpdeskWeb, :router

  use AshAuthentication.Phoenix.Router
  import HelpdeskWeb.UserAuth
  # import AshAuthentication.Plug.Helpers, only: [retrieve_from_bearer: 2, set_actor: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HelpdeskWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  pipeline :api_authenticated do
    plug :get_actor_from_ash_token
    plug :put_tenant
  end

  scope "/", HelpdeskWeb do
    pipe_through [:browser]

    ash_authentication_live_session :authentication_required,
      on_mount: {HelpdeskWeb.LiveUserAuth, :live_user_required} do
      # Put live routes that require a user to be logged in here
      live("/auth/settings", Live.SettingsLive.Index, :index)
      live("/auth/:org_slug/tickets", Live.TicketLive.Index, :index)
      live("/auth/:org_slug/tickets/new", Live.TicketLive.Index, :new)
      live("/auth/:org_slug/tickets/:id/edit", Live.TicketLive.Index, :edit)

      live("/auth/:org_slug/tickets/:id", Live.TicketLive.Show, :show)
      live("/auth/:org_slug/tickets/:id/show/edit", Live.TicketLive.Show, :edit)

      live("/auth/:org_slug/representatives", Live.RepresentativeLive.Index, :index)
      live("/auth/:org_slug/representatives/new", Live.RepresentativeLive.Index, :new)
      live("/auth/:org_slug/representatives/:id/edit", Live.RepresentativeLive.Index, :edit)

      live("/auth/:org_slug/representatives/:id", Live.RepresentativeLive.Show, :show)
      live("/auth/:org_slug/representatives/:id/show/edit", Live.RepresentativeLive.Show, :edit)
    end

    ash_authentication_live_session :authentication_optional,
      on_mount: {HelpdeskWeb.LiveUserAuth, :live_user_optional} do
      # Put live routes that allow a user to be logged in *or* logged out here
    end

    ash_authentication_live_session :authentication_rejected,
      on_mount: {HelpdeskWeb.LiveUserAuth, :live_no_user} do
      # Put live routes that a user who is logged in should never see here
    end
  end

  scope "/api/json" do
    pipe_through [:api, :api_authenticated]

    forward "/swaggerui",
            OpenApiSpex.Plug.SwaggerUI,
            path: "/api/json/open_api",
            default_model_expand_depth: 4

    forward "/", HelpdeskWeb.AshJsonApiRouter
  end

  scope "/", HelpdeskWeb do
    pipe_through :browser

    get "/", PageController, :home
    auth_routes AuthController, Helpdesk.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{HelpdeskWeb.LiveUserAuth, :live_no_user}]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth"
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelpdeskWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:helpdesk, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HelpdeskWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
