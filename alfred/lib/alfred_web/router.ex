defmodule AlfredWeb.Router do
  use AlfredWeb, :router

  pipeline :browser do
    plug Ueberauth
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AlfredWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin do
    plug AlfredWeb.SessionPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AlfredWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/auth", AlfredWeb do
    pipe_through :browser

    get "/login", AuthController, :new_session
    post "/login", AuthController, :create_session
    delete "/logout", AuthController, :logout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/", AlfredWeb do
    pipe_through :browser

    live "/overlay", OverlayLive
  end

  scope "/admin", AlfredWeb do
    pipe_through :browser
    pipe_through :admin

    live "/", AdminLive
    resources "/commands", CommandController
  end

  scope "/api", AlfredWeb do
    pipe_through :api

    post "/overlay", OverlayController, :trigger_event
  end

  scope "/spotify", AlfredWeb do
    get "/authorize", SpotifyController, :authorize
    get "/authenticate", SpotifyController, :authenticate
  end

  scope "/webhooks", AlfredWeb do
    post "/twitch", TwitchController, :webhook
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AlfredWeb.Telemetry
    end
  end
end
