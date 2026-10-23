FROM docker.io/library/ruby:4.0.7

WORKDIR /rails

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT=development:test

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

EXPOSE 3000
CMD ["sh", "-c", "bin/rails db:prepare && bin/rails server"]
