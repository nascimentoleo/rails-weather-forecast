class AddressValidator
  MAX_ADDRESS_LENGTH = 255

  class InvalidAddressError < StandardError; end

  def self.call(address)
    normalized_address = address.to_s.gsub(/[[:cntrl:]]/, " ").squish

    raise InvalidAddressError, "Address is required" if normalized_address.empty?
    raise InvalidAddressError, "Address must be at most #{MAX_ADDRESS_LENGTH} characters" if normalized_address.length > MAX_ADDRESS_LENGTH

    normalized_address
  end
end
