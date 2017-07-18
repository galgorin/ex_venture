use Mix.Config

config :logger,
  level: :error

config :ex_mud, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_mud_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_mud, :networking,
  server: false,
  socket_module: Test.Networking.Socket

config :ex_mud, :game,
  room: Test.Game.Room

config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1