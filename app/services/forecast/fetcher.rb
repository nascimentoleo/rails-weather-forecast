class Forecast
  class Fetcher
    class ServiceError < StandardError; end

    def self.call(address:, forecast:)
      response = OpenMeteo::Client.new.forecast(
        latitude: address.latitude,
        longitude: address.longitude,
        temperature_unit: forecast.units,
        forecast_days: forecast.days
      )

      Forecast.new(
        units: forecast.units,
        days: forecast.days,
        current_temperature: response.fetch("current").fetch("temperature_2m"),
        daily_temperatures: daily_temperatures(response.fetch("daily"))
      )
    rescue OpenMeteo::TimeoutError
      raise ServiceError, "Weather service timed out, please try again"
    rescue OpenMeteo::Error, KeyError
      raise ServiceError, "Could not reach the weather service"
    end

    # Open-Meteo returns one array per field; this regroups them into one hash per day:
    #   { "time" => ["2026-10-21", "2026-10-22"], "temperature_2m_max" => [17.8, 18.5], "temperature_2m_min" => [8.6, 5.6] }
    #   becomes [{ date: "2026-10-21", high: 17.8, low: 8.6 }, { date: "2026-10-22", high: 18.5, low: 5.6 }]
    def self.daily_temperatures(daily)
      dates = daily.fetch("time")
      highs = daily.fetch("temperature_2m_max")
      lows = daily.fetch("temperature_2m_min")

      dates.zip(highs, lows).map { |date, high, low| { date: date, high: high, low: low } }
    end

    private_class_method :daily_temperatures
  end
end
