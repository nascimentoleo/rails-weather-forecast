module Forecast
  class CachedFetcher
    def self.call(address_output:, forecast_input:)
      cache_key = "forecast/#{address_output.zip}/#{forecast_input.units}/#{forecast_input.days}"
      from_cache = true

      forecast_output = Rails.cache.fetch(cache_key, **Rails.configuration.cache_options) do
        from_cache = false
        Forecast::Fetcher.call(address: address_output, forecast_input: forecast_input)
      end

      forecast_output.from_cache = from_cache
      forecast_output
    end
  end
end
