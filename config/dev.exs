import Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n"

config :logger, :console,
  level: :debug,
  format: "$date $time [$level] $metadata$message\n"
