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
      # define process that will have all the required models loaded into memory
      {Nx.Serving, serving: serving(), name: Alfred.Serving},
      # OBS websocket client
      {Alfred.Workers.OBS,
       uri: "ws://localhost:4455", state: nil, opts: [name: {:local, :obs_websocket_client}]}
    ]

    children =
      if System.get_env("MIX_ENV") == "test" do
        children
      else
        children ++
          [
            # git project watcher to compute diffs
            Alfred.Workers.Git,
            # Fetch Spotify current song
            Alfred.Workers.Spotify,
            # Fetch data from Twitch
            Alfred.Workers.Twitch,
            # Voice worker
            Alfred.Workers.Voice
          ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Alfred.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp serving do
    {:ok, model} = Bumblebee.load_model({:hf, "pysentimiento/robertuito-sentiment-analysis"})

    {:ok, tokenizer} =
      Bumblebee.load_tokenizer({:hf, "pysentimiento/robertuito-sentiment-analysis"})

    Bumblebee.Text.text_classification(model, tokenizer,
      compile: [batch_size: 1, sequence_length: 100],
      defn_options: [compiler: EXLA]
    )
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlfredWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
