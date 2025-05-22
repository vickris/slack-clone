defmodule SlackClone.Repo do
  use Ecto.Repo,
    otp_app: :slack_clone,
    adapter: Ecto.Adapters.Postgres
end
