use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: :dev

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"zOTe<CdZhC6}@,K%n^1N4$F2yCF5YMKS/v$p^:TT50Ii:p`0aqjZgNh|}^6J4b;1"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"=7Zvb*DKJ:I<W:W.B[tA:bN;tJS~o7D]3kXA_@6z!5Zuu2=EvuZ/~Q[,d[6SEQy)"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :dojo_drops do
  set version: current_version(:dojo_drops)
end

