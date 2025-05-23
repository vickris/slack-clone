defmodule SlackClone.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SlackCloneWeb.Telemetry,
      SlackClone.Repo,
      {DNSCluster, query: Application.get_env(:slack_clone, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SlackClone.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SlackClone.Finch},
      # Start a worker by calling: SlackClone.Worker.start_link(arg)
      # {SlackClone.Worker, arg},
      # Start to serve requests, typically the last entry
      SlackCloneWeb.Presence,
      SlackCloneWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SlackClone.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SlackCloneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
