defmodule Logserver.Repo do
  use Ecto.Repo,
    otp_app: :logserver,
    adapter: Ecto.Adapters.SQLite3
end
