module Address
  class CachedFetcher
    EXPIRES_IN = 30.minutes

    def self.call(address_input)
      cache_key = "addresses/#{address_input.full_address.downcase}"

      addresses_attributes = Rails.cache.fetch(cache_key, expires_in: EXPIRES_IN) do
        Address::Fetcher.call(address_input).map(&:attributes)
      end

      addresses_attributes.map { |attributes| Address::Output.new(attributes) }
    end
  end
end
