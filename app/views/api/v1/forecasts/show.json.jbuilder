json.address do
  json.extract! @address_output, :full_address, :zip, :latitude, :longitude
end

json.forecast do
  json.extract! @forecast_output, :units, :current_temperature, :daily_temperatures
end
