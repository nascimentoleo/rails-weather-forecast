require "net/http"

module OpenMeteo
  class Error < StandardError; end
  class TimeoutError < Error; end
  class RateLimitError < Error; end

  class Client
    BASE_URL = "https://api.open-meteo.com/v1/forecast"
    TIMEOUT_IN_SECONDS = 5
    CURRENT_FIELDS = "temperature_2m"
    DAILY_FIELDS = "temperature_2m_max,temperature_2m_min"

    def forecast(latitude:, longitude:, temperature_unit:, forecast_days:)
      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form(
        latitude: latitude,
        longitude: longitude,
        current: CURRENT_FIELDS,
        daily: DAILY_FIELDS,
        temperature_unit: temperature_unit,
        forecast_days: forecast_days,
        timezone: "auto"
      )

      response = get(uri)
      raise RateLimitError, "Open-Meteo rate limit reached" if response.is_a?(Net::HTTPTooManyRequests)
      raise Error, "Open-Meteo responded with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      raise Error, "Open-Meteo returned an unexpected response" unless body.is_a?(Hash)

      body
    rescue Timeout::Error => error
      raise TimeoutError, error.message
    rescue SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Zlib::Error, JSON::ParserError => error
      raise Error, error.message
    end

    private

    def get(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT_IN_SECONDS, read_timeout: TIMEOUT_IN_SECONDS) do |http|
        http.get(uri.request_uri)
      end
    end
  end
end
