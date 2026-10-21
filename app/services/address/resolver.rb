class Address
  class Resolver
    class NotFoundError < StandardError; end
    class ServiceError < StandardError; end

    def self.call(address)
      result = Geocoder.search(address.full_address, params: { countrycodes: "us" }).first
      resolved_address = Address.new(
        full_address: address.full_address,
        zip: result&.postal_code,
        latitude: result&.latitude,
        longitude: result&.longitude
      )

      raise NotFoundError, "Could not find a zip code for this address" if resolved_address.zip.nil?

      resolved_address
    rescue Geocoder::OverQueryLimitError
      raise ServiceError, "Address lookup rate limit reached, please try again shortly"
    rescue Timeout::Error
      raise ServiceError, "Address lookup timed out, please try again"
    rescue Geocoder::Error, SocketError, SystemCallError
      raise ServiceError, "Could not reach the address lookup service"
    end
  end
end
