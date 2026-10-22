module Address
  class Input
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Attributes::Normalization

    MIN_LENGTH = 5
    MAX_LENGTH = 255
    CONTROL_CHARACTERS = /[[:cntrl:]]/

    attribute :full_address, :string

    # Normalize and remove invalid characters, to avoid malformed strings.
    # Converts this "  350 5th\u0000Ave,\tNew   York, NY " to this "350 5th Ave, New York, NY"
    normalizes :full_address, with: ->(full_address) { full_address.gsub(CONTROL_CHARACTERS, " ").squish }

    validates :full_address, presence: { message: "is required" }
    validates :full_address, length: { minimum: MIN_LENGTH, maximum: MAX_LENGTH,
                                       too_short: "must be at least %{count} characters",
                                       too_long: "must be at most %{count} characters" },
                             allow_blank: true
  end
end
