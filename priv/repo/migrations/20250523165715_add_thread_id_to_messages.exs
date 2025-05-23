defmodule SlackClone.Repo.Migrations.AddThreadIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :thread_id, references(:messages, on_delete: :nothing)
    end
  end
end
