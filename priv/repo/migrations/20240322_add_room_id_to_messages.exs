defmodule Logserver.Repo.Migrations.AddRoomIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:log_messages) do
      add :room_id, :string, null: false, default: "lobby"
    end

    create index(:log_messages, [:room_id])
  end
end
