# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :dojo_drops,
  ecto_repos: [DojoDrops.Repo]

# Configures the endpoint
config :dojo_drops, DojoDropsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DTx5JrA/bg5S2CHx7pTTeD9yDdMynvQ0hz7+PQ3D8/9eU4VUdP5QBkDO2a2R1f6w",
  render_errors: [view: DojoDropsWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: DojoDrops.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :dojo_drops, :dropbox, access_token: "${DROPBOX_TOKEN}"
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
