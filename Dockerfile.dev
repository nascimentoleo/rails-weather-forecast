FROM docker.io/library/ruby:4.0.7

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install && gem install foreman

ENV BINDING=0.0.0.0

CMD ["sh", "-c", "rm -f tmp/pids/server.pid && bin/rails db:prepare && bin/dev"]
