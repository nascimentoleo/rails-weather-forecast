module Address
  class Fetcher
    class NotFoundError < StandardError; end
    class ServiceError < StandardError; end

    def self.call(address_input)
      result = Geocoder.search(address_input.full_address, params: { countrycodes: "us" }).first
      address = Address::Output.new(
        full_address: address_input.full_address,
        zip: result&.postal_code,
        latitude: result&.latitude,
        longitude: result&.longitude
      )

      raise NotFoundError, "Could not find a zip code for this address" if address.zip.nil?

      address
    rescue Geocoder::OverQueryLimitError
      raise ServiceError, "Address lookup rate limit reached, please try again shortly"
    rescue Timeout::Error
      raise ServiceError, "Address lookup timed out, please try again"
    rescue Geocoder::Error, SocketError, SystemCallError
      raise ServiceError, "Could not reach the address lookup service"
    end
  end
end
