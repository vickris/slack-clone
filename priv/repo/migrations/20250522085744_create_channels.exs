defmodule SlackClone.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string, null: false
      add :description, :text
      add :creator_id, references(:users, on_delete: :nothing)
      timestamps()
    end

    create unique_index(:channels, [:name])
  end
end
