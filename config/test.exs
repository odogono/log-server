import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :logserver, Logserver.Repo,
  database:
    Path.expand(
      "../priv/logserver/logserver_test#{System.get_env("MIX_TEST_PARTITION")}.db",
      Path.dirname(__ENV__.file)
    ),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :logserver, LogserverWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "UzHzyGHex1KQbl5pZqCvoCk/vV4MSfFkn0vVay0O2ahX26FC87kgPpPACxuXppB7",
  server: false

# In test we don't send emails.
config :logserver, Logserver.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
