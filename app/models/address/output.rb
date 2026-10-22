module Address
  class Output
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Attributes::Normalization

    US_ZIP_CODE = /\d{5}/

    attribute :full_address, :string
    attribute :city, :string
    attribute :state, :string
    attribute :zip, :string
    attribute :latitude, :float
    attribute :longitude, :float
    attribute :from_cache, :boolean, default: false

    # Normalize zip code to accept only us format
    normalizes :zip, with: ->(zip) { zip[US_ZIP_CODE] }
  end
end
