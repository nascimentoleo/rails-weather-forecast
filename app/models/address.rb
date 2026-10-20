class Address
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  MAX_LENGTH = 255
  CONTROL_CHARACTERS = /[[:cntrl:]]/
  US_ZIP_CODE = /\d{5}/

  attribute :full_address, :string
  attribute :zip, :string
  attribute :latitude, :float
  attribute :longitude, :float

  # Normalize and remove invalid characters, to avoid malformed strings.
  # Converts this "  350 5th\u0000Ave,\tNew   York, NY " to this "350 5th Ave, New York, NY"
  normalizes :full_address, with: ->(full_address) { full_address.gsub(CONTROL_CHARACTERS, " ").squish }
  # Normalize zip code to accept only us format
  normalizes :zip, with: ->(zip) { zip[US_ZIP_CODE] }

  validates :full_address, presence: { message: "is required" },
                           length: { maximum: MAX_LENGTH, message: "must be at most %{count} characters" }
end
