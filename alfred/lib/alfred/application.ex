defmodule Alfred.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Alfred.Repo,
      # Start the Telemetry supervisor
      AlfredWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Alfred.PubSub},
      # Start the Endpoint (http/https)
      AlfredWeb.Endpoint,
      # twitch irc chat supervisor
      Alfred.Chat,
      # Start a worker by calling: Alfred.Worker.start_link(arg)
      # {Alfred.Worker, arg}
      # git project watcher to compute diffs
      Alfred.Workers.Git,
      # Fetch Spotify current song
      Alfred.Workers.Spotify
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Alfred.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlfredWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
