import Config

config :bonfire_valueflows_observe,
  templates_path: "lib"

# specify what types a observation can have as context
config :bonfire_valueflows_observe, ValueFlows.Observe.Units,
  valid_contexts: [ValueFlows.Observe.Units]
