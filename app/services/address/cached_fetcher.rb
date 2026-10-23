module Address
  class CachedFetcher
    def self.call(address_input)
      from_cache = true

      addresses_attributes = Rails.cache.fetch(cache_key(address_input.full_address), **Rails.configuration.cache_options) do
        from_cache = false
        Address::Fetcher.call(address_input).map do |address|
          Rails.cache.write(cache_key(address.full_address), [ address.attributes ], **Rails.configuration.cache_options)
          address.attributes
        end
      end

      addresses_attributes.map { |attributes| Address::Output.new(attributes.merge("from_cache" => from_cache)) }
    end

    def self.cache_key(full_address)
      "addresses/#{full_address.downcase}"
    end

    private_class_method :cache_key
  end
end
