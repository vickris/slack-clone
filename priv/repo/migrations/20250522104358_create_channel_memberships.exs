defmodule SlackClone.Repo.Migrations.CreateChannelMemberships do
  use Ecto.Migration

  def change do
    create table(:channel_memberships) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :channel_id, references(:channels, on_delete: :delete_all)
      timestamps()
    end

    create unique_index(:channel_memberships, [:user_id, :channel_id])
  end
end
