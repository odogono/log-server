defmodule Logserver.Repo do
  use Ecto.Repo,
    otp_app: :logserver,
    adapter: Ecto.Adapters.Postgres
end
