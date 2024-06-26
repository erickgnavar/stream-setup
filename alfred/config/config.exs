# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :alfred,
  ecto_repos: [Alfred.Repo],
  migration_timestamps: [type: :utc_datetime]

# Configures the endpoint
config :alfred, AlfredWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: AlfredWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Alfred.PubSub,
  live_view: [signing_salt: "omV3ZA6n"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :spotify_ex,
  auth_client: Spotify.Authentication,
  callback_url: "http://localhost:5555/spotify/authenticate",
  scopes: ["user-read-currently-playing", "user-modify-playback-state"]

config :ueberauth, Ueberauth,
  providers: [
    twitch:
      {Ueberauth.Strategy.Twitch,
       [
         default_scope:
           "moderator:read:followers channel:read:subscriptions channel:read:redemptions"
       ]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
