json.address do
  json.extract! @address_output, :full_address, :zip, :latitude, :longitude, :from_cache
end

json.forecast do
  json.extract! @forecast_output, :units, :current_temperature, :daily_temperatures, :from_cache
end
