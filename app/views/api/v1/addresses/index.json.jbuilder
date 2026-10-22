json.addresses @addresses do |address|
  json.extract! address, :full_address, :city, :state, :zip, :latitude, :longitude
end
