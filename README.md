# Weather Forecast

A Ruby on Rails app that takes a US address and shows its current temperature and a daily forecast (highs and lows). Results are cached for 30 minutes, and the app shows when a result came from the cache.

It works as a web page and as a JSON API, and needs **no API keys or environment variables**: clone it, run `bin/setup`, and use it.

## Features

- Search a US address, pick it from a list of matches, and see the forecast for its zip code
- Choose the units (°C or °F) and the number of days (1–16)
- Use the full web UI or only the JSON API
- Addresses and forecasts cached for 30 minutes
- Interactive API documentation (Swagger UI) at `/api-docs`

## Tech stack

| Area | Technology |
|---|---|
| Language and framework | Ruby 4.0.7, Rails 8.1.4 |
| Cache | [Solid Cache](https://github.com/rails/solid_cache) |
| Frontend | [Turbo](https://turbo.hotwired.dev) (Hotwire) and [Tailwind CSS](https://tailwindcss.com) |
| Address lookup | [Nominatim](https://nominatim.org/release-docs/latest/api/Search/) (OpenStreetMap), through the [geocoder](https://github.com/alexreisner/geocoder) gem |
| Weather data | [Open-Meteo Forecast API](https://open-meteo.com/en/docs)|
| Tests | [RSpec](https://github.com/rspec/rspec-rails), [WebMock](https://github.com/bblimke/webmock), [FactoryBot](https://github.com/thoughtbot/factory_bot_rails) |
| API docs | [rswag](https://github.com/rswag/rswag) (OpenAPI 3 + Swagger UI) |
| Code quality | [RuboCop](https://github.com/rails/rubocop-rails-omakase) |

## Getting started

```sh
git clone https://github.com/nascimentoleo/rails-weather-forecast.git
cd rails-weather-forecast
```

### With Docker (recommended)

Requires [Docker](https://docs.docker.com/get-started/get-docker/).

```sh
docker compose up      # builds the image and starts the server
```

### Without Docker

Requires Ruby 4.0.7. Install it with a Ruby version manager, such as [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com):

```sh
# with rbenv (it picks up the project's .ruby-version file)
rbenv install 4.0.7

# or with asdf
asdf plugin add ruby
asdf install ruby 4.0.7
asdf set ruby 4.0.7
```

Then install the gems and start the server:

```sh
bin/setup
```

To start the server again later, run `bin/dev`.

With either option, open `http://localhost:3000` in your browser.

## Usage

### Web page

1. Type an address and press **Enter**: a list of matching addresses appears.
2. Pick one to see its current temperature and daily forecast.
3. Change the units or days and click **Search** to reload the forecast.

### API only

The API can be used on its own, as a backend:

| Endpoint | What it does |
|---|---|
| `GET /api/v1/addresses?full_address=…` | Lists the US addresses that match the text |
| `GET /api/v1/forecast?full_address=…&units=…&days=…` | Returns the daily forecast for the address provided |

```sh
curl "http://localhost:3000/api/v1/forecast?full_address=1180%20Seven%20Seas%20Dr,%20Lake%20Buena%20Vista&units=fahrenheit&days=3"
```

For parameters, responses and error codes, see the API documentation: open `http://localhost:3000/api-docs` or read [`swagger/v1/swagger.yaml`](swagger/v1/swagger.yaml).

## How it works

```mermaid
flowchart LR
    client([Web page / API client]) -- address --> app[Weather Forecast app]
    app <--> cache[(Cache<br/>30 min)]
    app -- address --> nominatim[Nominatim]
    app -- coordinates --> openmeteo[Open-Meteo]
```

1. **Address lookup.** The address is searched on Nominatim, which returns the matching US addresses with their zip codes and coordinates. Addresses without a zip code are dropped.
2. **Weather lookup.** The forecast for that zip code is fetched from Open-Meteo, using the address's coordinates and the chosen units and days.
3. **Response.** The result is shown on the web page or returned as JSON, with a flag telling whether the address and the forecast came from the cache.

Each step is cached for 30 minutes, so repeated searches don't call the external services again.

## Tests and checks

`bin/ci` runs everything below except the Swagger regeneration (plus `bin/setup` and an importmap audit). Each check can also be run on its own:

```sh
bin/ci                      # all checks in one go
bundle exec rspec           # test suite (with Docker: docker compose exec web bundle exec rspec)
bin/rubocop                 # code style
bin/brakeman                # security analysis
bin/bundler-audit           # known vulnerabilities in gems
RAILS_ENV=test bin/rails rswag:specs:swaggerize   # regenerate swagger/v1/swagger.yaml
```

## Trade-offs

- **Nominatim and Open-Meteo, because they need no API keys.** There's nothing to configure: clone, set up, and use. The cost is that both are free public services with no SLA. Nominatim allows about [1 request per second](https://operations.osmfoundation.org/policies/nominatim/) and requires a User-Agent, and Open-Meteo is [free for non-commercial use](https://open-meteo.com/en/terms).
- **No application database.** The app only stores its cache: requests and results are plain Ruby objects, not database records, so there are no tables or migrations. The only exception is production's cache database, explained next.
- **Solid Cache instead of Redis.** Development caches in memory. Production uses Rails' Solid Cache, which keeps cache entries in a SQLite file. That means one less service to install, run and pay for, and one less dependency to maintain. It's slower than Redis's in-memory store and, on SQLite, doesn't suit several servers sharing one cache, which is fine at this scale.
- **The forecast is cached per zip code.** The address is converted to a zip code first, and the forecast is cached by zip, units and days. Two addresses in the same zip share one forecast.
- **US only.** Since the forecast is cached by zip code, including more countries would make zip codes overlap: for example, 75001 is both Addison, Texas and Paris, France, so both would share one cache entry. This is why the app only searches US addresses. Caching by coordinates instead would remove the overlap, but every address in the same zip code has different coordinates, so each one would become its own cache entry instead of one entry per zip code.
- **Open-Meteo limitations.** Units are Celsius or Fahrenheit only (no Kelvin), and the forecast covers 1 to 16 days. Each units and days combination is a separate cache entry, so more options mean fewer cache hits.

## License

[MIT](LICENSE)
