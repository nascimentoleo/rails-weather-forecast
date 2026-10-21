module Forecast
  class Input
    include ActiveModel::Model
    include ActiveModel::Attributes

    UNITS = %w[fahrenheit celsius].freeze
    DEFAULT_UNITS = "celsius"
    DEFAULT_DAYS = 7
    MAX_DAYS = 16

    attribute :units, :string, default: DEFAULT_UNITS
    attribute :days, :integer, default: DEFAULT_DAYS

    validates :units, inclusion: { in: UNITS, message: "must be one of: #{UNITS.join(", ")}" }
    validates :days, numericality: { only_integer: true, in: 1..MAX_DAYS, message: "must be between 1 and #{MAX_DAYS}" }
  end
end
