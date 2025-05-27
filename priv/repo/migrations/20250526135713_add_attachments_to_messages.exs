defmodule SlackClone.Repo.Migrations.AddAttachmentsToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :attachments, {:array, :string}, default: []
    end
  end
end
