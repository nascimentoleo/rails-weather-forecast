module Address
  class Searcher
    class ServiceError < StandardError; end

    MAX_RESULTS = 10

    def self.call(address_input)
      results = Geocoder.search(address_input.full_address, params: { countrycodes: "us", limit: MAX_RESULTS })
      addresses = results.map do |result|
        Address::Output.new(
          full_address: result.display_name,
          city: result.city,
          state: result.state,
          zip: result.postal_code,
          latitude: result.latitude,
          longitude: result.longitude
        )
      end

      addresses.select(&:zip)
    rescue Geocoder::OverQueryLimitError
      raise ServiceError, "Address lookup rate limit reached, please try again shortly"
    rescue Timeout::Error
      raise ServiceError, "Address lookup timed out, please try again"
    rescue Geocoder::Error, SocketError, SystemCallError
      raise ServiceError, "Could not reach the address lookup service"
    end
  end
end
