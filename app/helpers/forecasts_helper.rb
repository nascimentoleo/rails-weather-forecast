module ForecastsHelper
  UNIT_SYMBOLS = { "celsius" => "°C", "fahrenheit" => "°F" }.freeze

  def temperature(value, units)
    "#{value.round}#{UNIT_SYMBOLS.fetch(units)}"
  end

  def forecast_day(date)
    Date.parse(date.to_s).strftime("%a, %b %-d")
  end
end
