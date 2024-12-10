defmodule Logserver.Logging.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "log_messages" do
    field :type, :string
    field :content, :string
    field :timestamp, :naive_datetime_usec

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:type, :content, :timestamp])
    |> validate_required([:type, :content, :timestamp])
  end

  def ordered_messages(limit \\ 100) do
    from(m in __MODULE__,
      order_by: [desc: m.timestamp],
      limit: ^limit
    )
  end
end
