defmodule Logserver.Logging.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "log_messages" do
    field :type, :string
    field :content, :string
    field :timestamp, :naive_datetime_usec
    field :room_id, :string

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:type, :content, :timestamp, :room_id])
    |> validate_required([:type, :content, :timestamp, :room_id])
  end

  def ordered_messages(room_id, limit \\ 100) when is_integer(limit) do
    from(m in __MODULE__,
      where: m.room_id == ^room_id,
      order_by: [desc: m.timestamp],
      limit: ^limit
    )
  end

  def delete_message(timestamp, room_id) do
    from(m in __MODULE__,
      where: m.timestamp == ^timestamp and m.room_id == ^room_id
    )
  end
end
