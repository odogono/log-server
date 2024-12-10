defmodule Logserver.Repo.Migrations.CreateLogMessages do
  use Ecto.Migration

  def change do
    create table(:log_messages) do
      add :type, :string
      add :content, :text
      add :timestamp, :naive_datetime_usec

      timestamps()
    end

    create index(:log_messages, [:timestamp])
  end
end
