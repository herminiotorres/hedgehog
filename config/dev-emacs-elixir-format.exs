import Config

config :logger, :console,
  level: :debug,
  format: "[$level] $metadata$message\n"
