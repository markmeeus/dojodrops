FROM elixir:1.5.1
ENV DEBIAN_FRONTEND=noninteractive

RUN useradd -ms /bin/bash elixir_user \
  && adduser elixir_user root \
  && mix local.hex --force \
  && mix local.rebar --force \
  && mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez --force \
  && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get install -y -q nodejs

WORKDIR /app

COPY mix.* ./

RUN mix deps.get

COPY . .

RUN cd assets \
  && npm install \
  && cd ..

RUN mix phx.digest \
  && MIX_ENV=prod mix do compile, release --verbose --env=prod \
  && chown -R elixir_user:root /app

USER elixir_user
EXPOSE 4000
EXPOSE 4443
CMD ["/app/_build/prod/rel/dojo_drops/bin/dojo_drops", "foreground"]